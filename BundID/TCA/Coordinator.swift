import ComposableArchitecture
import TCACoordinators
import SwiftUI

struct CoordinatorState: Equatable, IndexedRouterState {
    var tokenURL: String?
    var setupPreviouslyFinished: Bool = false
    
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
}

enum CoordinatorAction: Equatable, IndexedRouterAction {
    case openURL(URL)
    case routeAction(Int, action: ScreenAction)
    case updateRoutes([Route<ScreenState>])
}

let coordinatorReducer: Reducer<CoordinatorState, CoordinatorAction, AppEnvironment> = .combine(
    Reducer { state, action, _ in
        switch action {
        case .openURL(let url):
            var tokenURL = url.absoluteString
            if url.scheme == "bundid" {
                tokenURL = tokenURL.replacingOccurrences(of: "bundid://", with: "eid://")
            }
            state.tokenURL = tokenURL
            if state.setupPreviouslyFinished {
                state.routes.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)), embedInNavigationView: true)
            } else {
                state.routes.presentSheet(.setupCoordinator(SetupCoordinatorState()), embedInNavigationView: true)
            }
            return .none
        default:
            return .none
        }
    },
    screenReducer
    .forEachIndexedRoute(environment: { $0 })
    .withRouteReducer(
        Reducer { state, action, _ in
            switch action {
            case .routeAction(_, .home(.triggerSetup)):
                state.routes.presentSheet(.setupCoordinator(SetupCoordinatorState()), embedInNavigationView: true)
                return .none
            case .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .intro(.chooseYes)))):
                if let tokenURL = state.tokenURL {
                    return Effect.routeWithDelaysIfUnsupported(state.routes) {
                        $0.dismiss()
                        $0.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)), embedInNavigationView: true)
                    }
                } else {
                    state.routes.dismiss()
                    return .none
                }
            case .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .error(.done)))):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .incorrectTransportPIN(.afterConfirmEnd)))):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .done(.done)))):
                if let tokenURL = state.tokenURL {
                    return Effect.routeWithDelaysIfUnsupported(state.routes) {
                        $0.dismiss()
                        $0.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)), embedInNavigationView: true)
                    }
                } else {
                    state.routes.dismiss()
                    return .none
                }
            case .routeAction(_, action: .home(.triggerIdentification(tokenURL: let tokenURL))):
                state.routes.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)), embedInNavigationView: true)
                return .none
            case .routeAction(_, action: .identificationCoordinator(.routeAction(_, action: .overview(.cancel)))):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .identificationCoordinator(.routeAction(_, action: .done(.close)))):
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
