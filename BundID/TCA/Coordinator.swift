import ComposableArchitecture
import TCACoordinators
import SwiftUI

struct CoordinatorState: Equatable, IndexedRouterState {
    var tokenURL: String?
    var states: [Route<ScreenState>]
    
    var routes: [Route<ScreenState>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .home(var state):
                        state.tokenURL = tokenURL
                        return .home(state)
                    default:
                        return screenState
                    }
                }
            }
        }
        set {
            states = newValue
        }
    }
    
    mutating func handleURL(_ url: String, environment: AppEnvironment) -> Effect<CoordinatorAction, Never> {
        guard url.hasPrefix("eid://") else { return .none }
        
        tokenURL = url
        if environment.storageManager.setupCompleted {
            routes.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: url)))
        } else {
            routes.presentSheet(.setupCoordinator(SetupCoordinatorState(tokenURL: tokenURL)))
        }
        return .none
    }
    
    mutating func handleAppStartWithoutURL(environment: AppEnvironment) -> Effect<CoordinatorAction, Never> {
        if environment.storageManager.setupCompleted {
            return .none
        } else {
            routes.presentSheet(.setupCoordinator(SetupCoordinatorState()))
            return .none
        }
    }
}

enum CoordinatorAction: Equatable, IndexedRouterAction {
    case openURL(URL)
    case onAppear
    case routeAction(Int, action: ScreenAction)
    case updateRoutes([Route<ScreenState>])
}

let coordinatorReducer: Reducer<CoordinatorState, CoordinatorAction, AppEnvironment> = .combine(
    Reducer { state, action, environment in
        switch action {
        case .openURL(let url):
            let tokenURL = url.absoluteString
            return state.handleURL(tokenURL, environment: environment)
        case .onAppear:
            guard let tokenURL = state.tokenURL else {
                return state.handleAppStartWithoutURL(environment: environment)
            }
            return state.handleURL(tokenURL, environment: environment)
        default:
            return .none
        }
    },
    screenReducer
        .forEachIndexedRoute(environment: { $0 })
        .withRouteReducer(
            Reducer { state, action, environment in
                guard case let .routeAction(_, action: routeAction) = action else { return .none }
                
                switch routeAction {
                case .home(.triggerSetup):
                    state.routes.presentSheet(.setupCoordinator(SetupCoordinatorState()))
                    return .none
                case .setupCoordinator(.routeAction(_, action: .intro(.chooseSetupAlreadyDone))):
                    if let tokenURL = state.tokenURL {
                        return Effect.routeWithDelaysIfUnsupported(state.routes) {
                            $0.dismiss()
                            $0.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)))
                        }
                    } else {
                        state.routes.dismiss()
                        return .none
                    }
                case .setupCoordinator(.routeAction(_, action: .error(.done))),
                        .identificationCoordinator(.routeAction(_, action: .cardError(.done))):
                    state.routes.dismiss()
                    return .none
                case .setupCoordinator(.afterConfirmEnd),
                        .identificationCoordinator(.afterConfirmEnd):
                    state.routes.dismiss()
                    return .none
                case .setupCoordinator(.routeAction(_, action: .done(.triggerIdentification))):
                    if let tokenURL = state.tokenURL {
                        return Effect.routeWithDelaysIfUnsupported(state.routes) {
                            $0.dismiss()
                            $0.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)))
                        }
                    } else {
                        state.routes.dismiss()
                        return .none
                    }
                case .setupCoordinator(.routeAction(_, action: .done(.done))):
                    state.routes.dismiss()
                    return .none
                case .home(.triggerIdentification(tokenURL: let tokenURL)):
                    state.routes.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)))
                    return .none
                case .identificationCoordinator(.routeAction(_, action: .overview(.cancel))),
                        .identificationCoordinator(.routeAction(_, action: .scan(.end))),
                        .identificationCoordinator(.routeAction(_, action: .done(.close))):
                    state.routes.dismiss()
                    return .none
                case .identificationCoordinator(.routeAction(_, action: .scan(.identifiedSuccessfullyWithoutRedirect))),
                        .identificationCoordinator(.routeAction(_, action: .scan(.identifiedSuccessfullyWithRedirect))),
                        .setupCoordinator(.routeAction(_, action: .scan(.scannedSuccessfully))):
                    environment.storageManager.updateSetupCompleted(true)
                    return .none
                case .identificationCoordinator(.routeAction(_, action: .done(.openURL(let url)))):
                    state.routes.dismiss()
                    UIApplication.shared.open(url)
                    return .none
                case .setupCoordinator(.confirmEnd):
                    state.routes.dismiss()
                    return .none
                case .identificationCoordinator(.confirmEnd):
                    state.routes.dismiss()
                    return .none
                default:
                    return .none
                }
            }
        )
)
#if DEBUG
.debug()
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
    }
}
