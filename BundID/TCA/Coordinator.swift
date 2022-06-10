import ComposableArchitecture
import TCACoordinators

struct CoordinatorState: Equatable, IndexedRouterState {
    var routes: [Route<ScreenState>]
}

enum CoordinatorAction: Equatable, IndexedRouterAction {
    case setupCoordinator(SetupCoordinatorAction)
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
            default:
                return .none
            }
        }
    ).debug()
