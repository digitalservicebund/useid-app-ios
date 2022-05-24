import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

struct CoordinatorState: Equatable, IndexedRouterState {
    var routes: [Route<ScreenState>]
}

enum CoordinatorAction: IndexedRouterAction {
    case routeAction(Int, action: ScreenAction)
    case updateRoutes([Route<ScreenState>])
}

let coordinatorReducer: Reducer<CoordinatorState, CoordinatorAction, AppEnvironment> = screenReducer
    .forEachIndexedRoute(environment: { $0 })
    .withRouteReducer(
        Reducer { state, action, _ in
            switch action {
            case .routeAction(_, ScreenAction.home(.triggerSetup)):
                state.routes.presentSheet(.setupIntro, embedInNavigationView: true)
            case .routeAction(_, ScreenAction.setupIntro(.chooseNo)):
                state.routes.push(.firstTimeUserPINLetter)
            case .routeAction(_, .firstTimeUserPINLetter(.chooseHasPINLetter)):
                state.routes.push(.firstTimeUserTransportPIN(FirstTimeUserTransportPINState()))
            case .routeAction(_, .firstTimeUserPINLetter(.chooseHasNoPINLetter)):
                print("Not implemented")
            case .routeAction(_, ScreenAction.setupIntro(.chooseYes)):
                print("Not implemented")
            case .routeAction(_, ScreenAction.firstTimeUserTransportPIN(FirstTimeUserTransportPINAction.done)):
                state.routes.push(.firstTimeUserChoosePINIntro)
            case .routeAction(_, ScreenAction.firstTimeUserChoosePINIntro(.continue)):
                state.routes.push(.firstTimeUserChoosePIN(FirstTimeUserPersonalPINState()))
            default:
                break
            }
            return .none
        }
    ).debug()
