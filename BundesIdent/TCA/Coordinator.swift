import Analytics
import ComposableArchitecture
import OpenEcard
import Sentry
import SwiftUI
import TCACoordinators

enum HandleURLError: Error, CustomStringConvertible, CustomNSError {
    case componentsInvalid
    case noTCTokenURLQueryItem
    case noWidgetSessionIdQueryItem
    case noUseIDSessionId
    case tcTokenURLEncodingError
    case tcTokenURLCreationFailed
    
    var description: String {
        switch self {
        case .componentsInvalid: return "URL components could not be created from URL"
        case .noTCTokenURLQueryItem: return "URL Components do not contain a tcTokenURL query parameter"
        case .noWidgetSessionIdQueryItem: return "URL Components do not contain a widgetSessionId query parameter"
        case .noUseIDSessionId: return "TCTokenURL does not contain a useIDSessionId parameter"
        case .tcTokenURLEncodingError: return "TCTokenURL could not be encoded"
        case .tcTokenURLCreationFailed: return "Could not create a url containing the tcTokenURL"
        }
    }
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: description]
    }
}

struct IdentificationInformation: Equatable {
    let useIDSessionId: String
    let widgetSessionId: String
    let tcTokenURL: URL
    
#if PREVIEW
    static var preview = IdentificationInformation(useIDSessionId: "12345", widgetSessionId: "56789", tcTokenURL: demoTCTokenURL)
#endif
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
    
    func extractIdentificationInformation(url: URL) -> IdentificationInformation? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            issueTracker.capture(error: HandleURLError.componentsInvalid)
            return nil
        }
        guard let tcTokenURLQueryItem = queryItems.last(where: { $0.name == "tcTokenURL" }),
              let urlString = tcTokenURLQueryItem.value else {
            issueTracker.capture(error: HandleURLError.noTCTokenURLQueryItem)
            return nil
        }
        guard let encodedTCTokenURL = OpenEcardImp().prepareTCTokenURL(urlString) else {
            issueTracker.capture(error: HandleURLError.tcTokenURLEncodingError)
            return nil
        }
        guard let widgetSessionIdQueryItem = queryItems.last(where: { $0.name == "widgetSessionId" }),
              let widgetSessionId = widgetSessionIdQueryItem.value else {
            issueTracker.capture(error: HandleURLError.noWidgetSessionIdQueryItem)
            return nil
        }
        
        // swiftlint:disable:next force_try
        let sessionIdRegex = try! NSRegularExpression(pattern: "\\/sessions\\/([a-f0-9-]*)\\/tc-token", options: .caseInsensitive)
        let range = NSRange(location: 0, length: urlString.utf16.count)
        let matches = sessionIdRegex.matches(in: urlString, range: range)
        
        guard matches.count == 1,
              matches[0].numberOfRanges == 2,
              let matchedRange = Range(matches[0].range(at: 1), in: urlString) else {
            issueTracker.capture(error: HandleURLError.noUseIDSessionId)
            return nil
        }
        
        let useIDSessionId = String(urlString[matchedRange])
        
        var urlComponents = URLComponents(string: "http://127.0.0.1:24727/eID-Client")!
        urlComponents.percentEncodedQueryItems = [URLQueryItem(name: "tcTokenURL", value: encodedTCTokenURL)]
        guard let tcTokenURL = urlComponents.url else {
            issueTracker.capture(error: HandleURLError.tcTokenURLCreationFailed)
            return nil
        }
        
        return IdentificationInformation(useIDSessionId: useIDSessionId, widgetSessionId: widgetSessionId, tcTokenURL: tcTokenURL)
    }
    
    func handleURL(state: inout State, _ url: URL) -> Effect<Action, Never> {
        guard let information = extractIdentificationInformation(url: url) else {
            logger.warning("Could not extract identification information from \(url, privacy: .sensitive)")
            return .none
        }
        
        let screen: Screen.State
        if storageManager.setupCompleted {
            screen = .identificationCoordinator(IdentificationCoordinator.State(identificationInformation: information,
                                                                                canGoBackToSetupIntro: false))
        } else {
            screen = .setupCoordinator(SetupCoordinator.State(identificationInformation: information))
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
                state.routes.presentSheet(.setupCoordinator(SetupCoordinator.State(identificationInformation: nil)))
                return .trackEvent(category: "firstTimeUser",
                                   action: "buttonPressed",
                                   name: "start",
                                   analytics: analytics)
            case .identificationCoordinator(.back(let identificationInformation)):
                return Effect.routeWithDelaysIfUnsupported(state.routes) {
                    $0.dismiss()
                    $0.presentSheet(.setupCoordinator(SetupCoordinator.State(identificationInformation: identificationInformation)))
                }
            case .setupCoordinator(.routeAction(_, action: .intro(.chooseSkipSetup(let identificationInformation)))):
                if let identificationInformation {
                    return Effect.routeWithDelaysIfUnsupported(state.routes) {
                        $0.dismiss()
                        $0.presentSheet(.identificationCoordinator(IdentificationCoordinator.State(identificationInformation: identificationInformation,
                                                                                                   canGoBackToSetupIntro: true)))
                    }
                } else {
                    state.routes.dismiss()
                    return .none
                }
            case .setupCoordinator(.routeAction(_, action: .done(.triggerIdentification(let identificationInformation)))):
                return Effect.routeWithDelaysIfUnsupported(state.routes) {
                    $0.dismiss()
                    $0.presentSheet(.identificationCoordinator(IdentificationCoordinator.State(identificationInformation: identificationInformation,
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
                 .identificationCoordinator(.routeAction(_, action: .share(.confirmClose))),
                 .identificationCoordinator(.routeAction(_, action: .done(.close))),
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
