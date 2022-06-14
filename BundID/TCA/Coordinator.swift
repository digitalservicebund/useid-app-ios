import ComposableArchitecture
import TCACoordinators
import SwiftUI

struct CoordinatorState: Equatable, IndexedRouterState {
    var routes: [Route<ScreenState>]
}

enum CoordinatorAction: Equatable, IndexedRouterAction {
    case routeAction(Int, action: ScreenAction)
    case updateRoutes([Route<ScreenState>])
}

let coordinatorReducer: Reducer<CoordinatorState, CoordinatorAction, AppEnvironment> = screenReducer
    .forEachIndexedRoute(environment: { $0 })
    .withRouteReducer(
        Reducer { state, action, _ in
            switch action {
            case .routeAction(_, .home(.triggerSetup)):
                state.routes.presentSheet(.setupCoordinator(SetupCoordinatorState()), embedInNavigationView: true)
                return .none
            case .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .error(.done)))):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .incorrectTransportPIN(.afterConfirmEnd)))):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .done(.done)))):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .home(.triggerIdentification(tokenURL: let tokenURL))):
                state.routes.presentSheet(.identificationCoordinator(IdentificationCoordinatorState(tokenURL: tokenURL)), embedInNavigationView: true)
                return .none
            case .routeAction(_, action: .identificationCoordinator(.routeAction(_, action: .overview(.cancel)))):
                state.routes.dismiss()
                return .none
            default:
                return .none
            }
        }
    ).debug()

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
