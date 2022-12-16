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

func extractTCTokenURL(url: URL, environment: AppEnvironment) -> URL? {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        environment.issueTracker.capture(error: HandleURLError.componentsInvalid)
        return nil
    }
    guard let queryItem = queryItems.last(where: { $0.name == "tcTokenURL" && $0.value != nil }),
          let urlString = queryItem.value else {
        environment.issueTracker.capture(error: HandleURLError.noTCTokenURLQueryItem)
        return nil
    }
    guard let encodedTCTokenURL = OpenEcardImp().prepareTCTokenURL(urlString) else {
        environment.issueTracker.capture(error: HandleURLError.tcTokenURLEncodingError)
        return nil
    }
    
    var urlComponents = URLComponents(string: "http://127.0.0.1:24727/eID-Client")!
    urlComponents.percentEncodedQueryItems = [URLQueryItem(name: "tcTokenURL", value: encodedTCTokenURL)]
    return urlComponents.url
}

struct CoordinatorState: Equatable, IndexedRouterState {
    var routes: [Route<ScreenState>]
    
    mutating func handleURL(_ url: URL, environment: AppEnvironment) -> Effect<CoordinatorAction, Never> {
        guard let tcTokenURL = extractTCTokenURL(url: url, environment: environment) else {
            environment.logger.warning("Could not extract tc token url from \(url, privacy: .sensitive)")
            return .none
        }
        
        let screen: ScreenState
        if environment.storageManager.setupCompleted {
            screen = .identificationCoordinator(IdentificationCoordinatorState(tokenURL: tcTokenURL, canGoBackToSetupIntro: false))
        } else {
            screen = .setupCoordinator(SetupCoordinatorState(tokenURL: tcTokenURL))
        }
        
        // In case setup or ident is shown, dismiss any shown sheets that screens
        // Afterwards dismiss setup or ident and show new flow
        if case .sheet(.identificationCoordinator, embedInNavigationView: _, onDismiss: _) = routes.last {
            return .concatenate(
                Effect(value: .routeAction(routes.count - 1, action: .identificationCoordinator(.dismiss))),
                dismiss(show: screen, environment: environment)
            )
        } else if case .sheet(.setupCoordinator, embedInNavigationView: _, onDismiss: _) = routes.last {
            return .concatenate(
                Effect(value: .routeAction(routes.count - 1, action: .setupCoordinator(.dismiss))),
                dismiss(show: screen, environment: environment)
            )
        } else {
            routes.presentSheet(screen)
            return .none
        }
    }
    
    mutating func handleAppStart(environment: AppEnvironment) -> Effect<CoordinatorAction, Never> {
        if environment.storageManager.setupCompleted {
            return .none
        } else {
            routes.presentSheet(.setupCoordinator(SetupCoordinatorState()))
            return .none
        }
    }
    
    private func dismiss(show screen: Screen, environment: AppEnvironment) -> Effect<CoordinatorAction, Never> {
        return Effect.routeWithDelaysIfUnsupported(routes) {
            $0.dismissAll()
            $0.presentSheet(screen)
        }
        .delay(for: 0.65, scheduler: environment.mainQueue)
        .eraseToEffect()
    }
}

extension Array: AnalyticsView where Element == Route<ScreenState> {
    public var route: [String] {
        flatMap(\.screen.route)
    }
}

enum CoordinatorAction: Equatable, IndexedRouterAction {
    case openURL(URL)
    case onAppear
    case didEnterBackground
    case routeAction(Int, action: ScreenAction)
    case updateRoutes([Route<ScreenState>])
}

private let trackingReducer: Reducer<CoordinatorState, CoordinatorAction, AppEnvironment> = Reducer { state, action, environment in
    switch action {
    case .routeAction, .onAppear:
        let routes = state.routes
        
        return .fireAndForget {
            environment.analytics.track(view: routes)
            environment.issueTracker.addViewBreadcrumb(view: routes)
        }
    case .didEnterBackground:
        return .fireAndForget {
            environment.analytics.dispatch()
        }
    default:
        return .none
    }
}

private let tokenReducer: Reducer<CoordinatorState, CoordinatorAction, AppEnvironment> = Reducer { state, action, environment in
    switch action {
    case .openURL(let url):
        return state.handleURL(url, environment: environment)
    case .onAppear:
        return state.handleAppStart(environment: environment)
    default:
        return .none
    }
}

let coordinatorReducer: Reducer<CoordinatorState, CoordinatorAction, AppEnvironment> = .combine(
    tokenReducer,
    screenReducer
        .forEachIndexedRoute(environment: { $0 })
        .withRouteReducer(
            Reducer { state, action, environment in
                guard case let .routeAction(_, action: routeAction) = action else { return .none }
                
                switch routeAction {
                case .home(.triggerSetup):
                    state.routes.presentSheet(.setupCoordinator(SetupCoordinatorState(tokenURL: nil)))
                    return .trackEvent(category: "firstTimeUser",
                                       action: "buttonPressed",
                                       name: "start",
                                       analytics: environment.analytics)
                case .identificationCoordinator(.back(let tokenURL)):
                    return Effect.routeWithDelaysIfUnsupported(state.routes) {
                        $0.dismiss()
                        $0.presentSheet(.setupCoordinator(SetupCoordinatorState(tokenURL: tokenURL)))
                    }
                case .setupCoordinator(.routeAction(_, action: .intro(.chooseSkipSetup(let tokenURL)))):
                    if let tokenURL = tokenURL {
                        return Effect.routeWithDelaysIfUnsupported(state.routes) {
                            $0.dismiss()
                            $0.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL,
                                                                                                      canGoBackToSetupIntro: true)))
                        }
                    } else {
                        state.routes.dismiss()
                        return .none
                    }
                case .setupCoordinator(.routeAction(_, action: .done(.triggerIdentification(let tokenURL)))):
                    return Effect.routeWithDelaysIfUnsupported(state.routes) {
                        $0.dismiss()
                        $0.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL,
                                                                                                  canGoBackToSetupIntro: false)))
                    }
#if PREVIEW
                case .home(.triggerIdentification(let tokenURL)):
                    return Effect(value: .openURL(tokenURL))
#endif
                case .identificationCoordinator(.dismiss),
                        .identificationCoordinator(.afterConfirmEnd),
                        .identificationCoordinator(.routeAction(_, action: .scan(.dismiss))),
                        .identificationCoordinator(.routeAction(_, action: .canScan(.dismiss))),
                        .setupCoordinator(.confirmEnd),
                        .setupCoordinator(.routeAction(_, action: .done(.done))),
                        .setupCoordinator(.afterConfirmEnd):
                    state.routes.dismiss()
                    return .none
                default:
                    return .none
                }
            }
        ),
    trackingReducer
)
#if DEBUG
.debug { environment in
    DebugEnvironment(printer: { environment.logger.debug("\($0)") })
}
#endif

struct CoordinatorView: View {
    let store: Store<CoordinatorState, CoordinatorAction>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /ScreenState.home,
                        action: ScreenAction.home,
                        then: HomeView.init)
                CaseLet(state: /ScreenState.setupCoordinator,
                        action: ScreenAction.setupCoordinator,
                        then: SetupCoordinatorView.init)
                CaseLet(state: /ScreenState.identificationCoordinator,
                        action: ScreenAction.identificationCoordinator,
                        then: IdentificationCoordinatorView.init)
            }
        }
        .accentColor(Asset.accentColor.swiftUIColor)
    }
}
