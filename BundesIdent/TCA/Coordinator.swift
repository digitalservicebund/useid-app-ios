import ComposableArchitecture
import TCACoordinators
import SwiftUI
import Analytics
import Sentry
import OpenEcard

enum HandleURLError: Error, CustomStringConvertible, CustomNSError {
    case componentsInvalid
    case noTCTokenURLQueryItem
    case tcTokenURLEncodingError
    
    var description: String {
        switch self {
        case .componentsInvalid: return "URL components could not be created from URL"
        case .noTCTokenURLQueryItem: return "URL Components do not contain a tcTokenURL query parameter"
        case .tcTokenURLEncodingError: return "TCTokenURL could not be encoded"
        }
    }
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: description]
    }
}

struct Coordinator: ReducerProtocol {
    @Dependency(\.idInteractionManager) var idInteractionManager
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.logger) var logger
    @Dependency(\.storageManager) var storageManager
    struct State: Equatable, IndexedRouterState {
        var routes: [Route<Screen.State>]
        var remoteConfiguration = RemoteConfiguration.State.initial
    }
    
    func dismiss(state: inout State, show screen: State.Screen) -> EffectTask<Coordinator.Action> {
        EffectTask.routeWithDelaysIfUnsupported(state.routes, scheduler: mainQueue) {
            $0.dismissAll()
            $0.presentSheet(screen)
        }
        .delay(for: 0.65, scheduler: mainQueue)
        .eraseToEffect()
    }
    
    func extractTCTokenURL(url: URL) -> URL? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            issueTracker.capture(error: HandleURLError.componentsInvalid)
            return nil
        }
        guard let queryItem = queryItems.last(where: { $0.name == "tcTokenURL" && $0.value != nil }),
              let urlString = queryItem.value else {
            issueTracker.capture(error: HandleURLError.noTCTokenURLQueryItem)
            return nil
        }
        guard let encodedTCTokenURL = OpenEcardImp().prepareTCTokenURL(urlString) else {
            issueTracker.capture(error: HandleURLError.tcTokenURLEncodingError)
            return nil
        }
        
        var urlComponents = URLComponents(string: "http://127.0.0.1:24727/eID-Client")!
        urlComponents.percentEncodedQueryItems = [URLQueryItem(name: "tcTokenURL", value: encodedTCTokenURL)]
        return urlComponents.url
    }
    
    func handleURL(state: inout State, _ url: URL) -> EffectTask<Action> {
        guard let tcTokenURL = extractTCTokenURL(url: url) else {
            logger.warning("Could not extract tc token url from \(url, privacy: .sensitive)")
            return .none
        }
        
        let screen: Screen.State
        if storageManager.setupCompleted {
            screen = .identificationCoordinator(IdentificationCoordinator.State(tokenURL: tcTokenURL, canGoBackToSetupIntro: false))
        } else {
            screen = .setupCoordinator(SetupCoordinator.State(tokenURL: tcTokenURL))
        }
        
        // In case setup or ident is shown, dismiss any shown sheets that screens
        // Afterwards dismiss setup or ident and show new flow
        if case .sheet(.identificationCoordinator, embedInNavigationView: _, onDismiss: _) = state.routes.last {
            return .concatenate(
                EffectTask(value: .routeAction(state.routes.count - 1, action: .identificationCoordinator(.dismiss))),
                dismiss(state: &state, show: screen)
            )
        } else if case .sheet(.setupCoordinator, embedInNavigationView: _, onDismiss: _) = state.routes.last {
            return .concatenate(
                EffectTask(value: .routeAction(state.routes.count - 1, action: .setupCoordinator(.dismiss))),
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
        case remoteConfiguration(RemoteConfiguration.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return Effect(value: .remoteConfiguration(.onAppStart))
            case .remoteConfiguration(.timeout), .remoteConfiguration(.loadingSuccess), .remoteConfiguration(.loadingError):
                let homeState: Home.State
        #if PREVIEW
                let previewIDInteractionManager = DependencyValues._current[keyPath: \.previewIDInteractionManager]
                homeState = Home.State(appVersion: Bundle.main.version, buildNumber: Bundle.main.buildNumber, isDebugModeEnabled: previewIDInteractionManager.isDebugModeEnabled)
        #else
                homeState = Home.State(appVersion: Bundle.main.version, buildNumber: Bundle.main.buildNumber)
        #endif
                return Effect(value: .updateRoutes([.root(.home(homeState))]))
            default:
                return .none
            }
        }
        Scope(state: \.remoteConfiguration, action: /Action.remoteConfiguration) {
            RemoteConfiguration()
        }
        Reduce(token)
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
                return EffectTask.routeWithDelaysIfUnsupported(state.routes, scheduler: mainQueue) {
                    $0.dismiss()
                    $0.presentSheet(.setupCoordinator(SetupCoordinator.State(tokenURL: tokenURL)))
                }
            case .setupCoordinator(.routeAction(_, action: .intro(.chooseSkipSetup(.some(let tokenURL))))):
                return EffectTask.routeWithDelaysIfUnsupported(state.routes, scheduler: mainQueue) {
                    $0.dismiss()
                    $0.presentSheet(.identificationCoordinator(IdentificationCoordinator.State(tokenURL: tokenURL,
                                                                                               canGoBackToSetupIntro: true)))
                }
            case .setupCoordinator(.routeAction(_, action: .alreadySetupConfirmation(.close))):
                state.routes.dismiss()
                return .none
            case .setupCoordinator(.routeAction(_, action: .done(.triggerIdentification(let tokenURL)))),
                 .setupCoordinator(.routeAction(_, action: .setupCANCoordinator(.routeAction(_, action: .canAlreadySetup(.triggerIdentification(tokenURL: let tokenURL)))))),
                 .setupCoordinator(.routeAction(_, action: .setupCANCoordinator(.routeAction(_, action: .setupCoordinator(.routeAction(_, action: .done(.triggerIdentification(tokenURL: let tokenURL)))))))):
                return EffectTask.routeWithDelaysIfUnsupported(state.routes, scheduler: mainQueue) {
                    $0.dismiss()
                    $0.presentSheet(.identificationCoordinator(IdentificationCoordinator.State(tokenURL: tokenURL,
                                                                                               canGoBackToSetupIntro: false)))
                }
#if PREVIEW
            case .home(.triggerIdentification(let tokenURL)):
                return EffectTask(value: .openURL(tokenURL))
#endif
            case .identificationCoordinator(.dismiss),
                 .identificationCoordinator(.routeAction(_, action: .identificationCANCoordinator(.dismiss))),
                 .identificationCoordinator(.afterConfirmEnd),
                 .identificationCoordinator(.routeAction(_, action: .identificationCANCoordinator(.afterConfirmEnd))),
                 .identificationCoordinator(.routeAction(_, action: .scan(.dismiss))),
                 .identificationCoordinator(.routeAction(_, action: .identificationCANCoordinator(.routeAction(_, action: .canScan(.dismiss))))),
                 .setupCoordinator(.confirmEnd),
                 .setupCoordinator(.routeAction(_, action: .done(.done))),
                 .setupCoordinator(.routeAction(_, action: .setupCANCoordinator(.routeAction(_, action: .canAlreadySetup(.done))))),
                 .setupCoordinator(.routeAction(_, action: .setupCANCoordinator(.dismiss))),
                 .setupCoordinator(.routeAction(_, action: .setupCANCoordinator(.routeAction(_, action: .canScan(.dismiss))))),
                 .setupCoordinator(.afterConfirmEnd),
                 .setupCoordinator(.routeAction(_, action: .setupCANCoordinator(.afterConfirmEnd))),
                 // This is bad, but we can not switch back to a previous coordinator while having another coordinator inbetween. See https://github.com/johnpatrickmorgan/FlowStacks/issues/23#issuecomment-1407125421
                 // We are only showing the setup coordinator in the end for the done screen
                 .setupCoordinator(.routeAction(_, action: .setupCANCoordinator(.routeAction(_, action: .setupCoordinator(.routeAction(_, action: .done(.done))))))):
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
        Reduce(tracking)
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
                CaseLet(state: /Screen.State.launch,
                        action: Screen.Action.launch,
                        then: LaunchView.init)
                CaseLet(state: /Screen.State.home,
                        action: Screen.Action.home,
                        then: HomeView.init)
                CaseLet(state: /Screen.State.setupCoordinator,
                        action: Screen.Action.setupCoordinator) { caseStore in
                    NavigationView {
                        SetupCoordinatorView(store: caseStore)
                    }
                    .accentColor(Asset.accentColor.swiftUIColor)
                    .ignoresSafeArea(.keyboard)
                }
                CaseLet(state: /Screen.State.identificationCoordinator,
                        action: Screen.Action.identificationCoordinator) { caseStore in
                    NavigationView {
                        IdentificationCoordinatorView(store: caseStore)
                    }
                    .accentColor(Asset.accentColor.swiftUIColor)
                    .ignoresSafeArea(.keyboard)
                }
            }
        }
        .accentColor(Asset.accentColor.swiftUIColor)
    }
}
