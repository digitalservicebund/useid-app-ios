import ComposableArchitecture
import TCACoordinators
import SwiftUI
import Analytics
import Sentry

struct Coordinator: ReducerProtocol {
    @Dependency(\.idInteractionManager) var idInteractionManager
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.logger) var logger
    @Dependency(\.storageManager) var storageManager
    struct State: Equatable, IndexedRouterState {
        var routes: [Route<Screen.State>]
    }
    
    func handleAppStart(state: inout State) -> Effect<Coordinator.Action, Never> {
        if storageManager.setupCompleted {
            return .none
        } else {
            state.routes.presentSheet(.setupCoordinator(SetupCoordinator.State()))
            return .none
        }
    }
    
    func dismiss(state: inout State, show screen: State.Screen) -> Effect<Coordinator.Action, Never> {
        Effect.routeWithDelaysIfUnsupported(state.routes) {
            $0.dismissAll()
            $0.presentSheet(screen)
        }
        .delay(for: 0.65, scheduler: mainQueue)
        .eraseToEffect()
    }
    
    func handleURL(state: inout State, _ url: URL) -> Effect<Coordinator.Action, Never> {
        let screen: Screen.State
        if storageManager.setupCompleted {
            screen = .identificationCoordinator(IdentificationCoordinator.State(tokenURL: url, canGoBackToSetupIntro: false))
        } else {
            screen = .setupCoordinator(SetupCoordinator.State(tokenURL: url))
        }
        
        // In case setup or ident is shown, dismiss any shown sheets that screens
        // Afterwards dismiss setup or ident and show new flow
        if case .sheet(.identificationCoordinator, embedInNavigationView: _, onDismiss: _) = state.routes.last {
            return .concatenate(
                Effect(value: .routeAction(state.routes.count - 1, action: .identificationCoordinator(.dismiss))),
                dismiss(state: &state, show: screen)
            )
        } else if case .sheet(.setupCoordinator, embedInNavigationView: _, onDismiss: _) = state.routes.last {
            return .concatenate(
                Effect(value: .routeAction(state.routes.count - 1, action: .setupCoordinator(.dismiss))),
                dismiss(state: &state, show: screen)
            )
        } else {
            state.routes.presentSheet(screen)
            return .none
        }
    }
    
    enum Action: Equatable, IndexedRouterAction {
        case openURL(URL)
        case onAppear
        case didEnterBackground
        case routeAction(Int, action: Screen.Action)
        case updateRoutes([Route<Screen.State>])
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce(self.token)
        Reduce { state, action in
            guard case .routeAction(_, action: let routeAction) = action else { return .none }
            switch routeAction {
            case .home(.triggerSetup):
                state.routes.presentSheet(.setupCoordinator(SetupCoordinator.State(tokenURL: nil)))
                return .trackEvent(category: "firstTimeUser",
                                   action: "buttonPressed",
                                   name: "start",
                                   analytics: analytics)
            case .identificationCoordinator(.back(let tokenURL)):
                return Effect.routeWithDelaysIfUnsupported(state.routes) {
                    $0.dismiss()
                    $0.presentSheet(.setupCoordinator(SetupCoordinator.State(tokenURL: tokenURL)))
                }
            case .setupCoordinator(.routeAction(_, action: .intro(.chooseSkipSetup(let tokenURL)))):
                if let tokenURL {
                    return Effect.routeWithDelaysIfUnsupported(state.routes) {
                        $0.dismiss()
                        $0.presentSheet(.identificationCoordinator(IdentificationCoordinator.State(tokenURL: tokenURL,
                                                                                                   canGoBackToSetupIntro: true)))
                    }
                } else {
                    state.routes.dismiss()
                    return .none
                }
            case .setupCoordinator(.routeAction(_, action: .done(.triggerIdentification(let tokenURL)))):
                return Effect.routeWithDelaysIfUnsupported(state.routes) {
                    $0.dismiss()
                    $0.presentSheet(.identificationCoordinator(IdentificationCoordinator.State(tokenURL: tokenURL,
                                                                                               canGoBackToSetupIntro: false)))
                }
#if PREVIEW
            case .home(.triggerIdentification(let tokenURL)):
                return Effect(value: .openURL(tokenURL))
#endif
            case .identificationCoordinator(.dismiss),
                 .identificationCoordinator(.routeAction(_, action: .identificationCANCoordinator(.dismiss))),
                 .identificationCoordinator(.afterConfirmEnd),
                 .identificationCoordinator(.routeAction(_, action: .identificationCANCoordinator(.afterConfirmEnd))),
                 .identificationCoordinator(.routeAction(_, action: .scan(.dismiss))),
                 .identificationCoordinator(.routeAction(_, action: .identificationCANCoordinator(.routeAction(_, action: .canScan(.dismiss))))),
                 .setupCoordinator(.confirmEnd),
                 .setupCoordinator(.routeAction(_, action: .done(.done))),
                 .setupCoordinator(.afterConfirmEnd):
                state.routes.dismiss()
                return .none
            default:
                return .none
            }
        }.forEachRoute {
            Screen()
        }
#if DEBUG
            ._printChanges(.log({ logger.debug("\($0)") }))
#endif
        Reduce(self.tracking)
    }
    
    func tracking(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .routeAction, .onAppear:
            let routes = state.routes
            
            return .fireAndForget {
                analytics.track(view: routes)
                issueTracker.addViewBreadcrumb(view: routes)
            }
        case .didEnterBackground:
            return .fireAndForget {
                analytics.dispatch()
            }
        default:
            return .none
        }
    }
    
    func token(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .openURL(let url):
            return handleURL(state: &state, url)
        case .onAppear:
            return handleAppStart(state: &state)
        default:
            return .none
        }
    }
}

private extension _ReducerPrinter {
    static func log(_ printLog: @escaping (String) -> Void) -> Self {
        Self { receivedAction, oldState, newState in
            @Dependency(\.context) var context
            guard context != .preview else { return }
            var target = ""
            target.write("received action:\n")
            CustomDump.customDump(receivedAction, to: &target, indent: 2)
            target.write("\n")
            target.write(diff(oldState, newState).map { "\($0)\n" } ?? "  (No state changes)\n")
            printLog(target)
        }
    }
}

extension [Route<Screen.State>]: AnalyticsView {
    public var route: [String] {
        flatMap(\.screen.route)
    }
}

struct CoordinatorView: View {
    let store: Store<Coordinator.State, Coordinator.Action>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /Screen.State.home,
                        action: Screen.Action.home,
                        then: HomeView.init)
                CaseLet(state: /Screen.State.setupCoordinator,
                        action: Screen.Action.setupCoordinator,
                        then: SetupCoordinatorView.init)
                CaseLet(state: /Screen.State.identificationCoordinator,
                        action: Screen.Action.identificationCoordinator,
                        then: IdentificationCoordinatorView.init)
            }
        }
        .accentColor(Asset.accentColor.swiftUIColor)
    }
}
