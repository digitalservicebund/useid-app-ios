import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

struct CoordinatorState: Equatable, IndexedRouterState {
    var transportPIN: String = ""
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
            case .routeAction(_, .home(.triggerSetup)):
                state.routes.presentSheet(.setupIntro, embedInNavigationView: true)
            case .routeAction(_, .setupIntro(.chooseNo)):
                state.routes.push(.setupTransportPINIntro)
            case .routeAction(_, .setupTransportPINIntro(.chooseHasPINLetter)):
                state.routes.push(.setupTransportPIN(SetupTransportPINState()))
            case .routeAction(_, .setupTransportPINIntro(.chooseHasNoPINLetter)):
                print("Not implemented")
            case .routeAction(_, .setupIntro(.chooseYes)):
                print("Not implemented")
            case .routeAction(_, .setupTransportPIN(.done(let transportPIN))):
                state.transportPIN = transportPIN
                state.routes.push(.setupPersonalPINIntro)
            case .routeAction(_, .setupPersonalPINIntro(.continue)):
                state.routes.push(.setupPersonalPIN(SetupPersonalPINState()))
            case .routeAction(_, action: .setupPersonalPIN(.done(pin: let pin))):
                state.routes.push(.setupScan(SetupScanState(transportPIN: state.transportPIN, newPIN: pin)))
            case .routeAction(_, action: .setupScan(.scannedSuccessfully)):
                state.routes.push(.setupDone)
            case .routeAction(_, action: .setupScan(.wrongTransportPIN(attempts: let attempts))):
                state.routes.presentSheet(.setupIncorrectTransportPIN(SetupIncorrectTransportPINState(remainingAttempts: attempts)), embedInNavigationView: true)
            case .routeAction(_, action: .setupDone(.done)):
                state.routes.dismiss()
            case .routeAction(_, action: .setupIncorrectTransportPIN(.done(let transportPIN))):
                state.transportPIN = transportPIN
                state.routes.dismiss()
            case .routeAction(_, action: .setupIncorrectTransportPIN(.confirmEnd)):
                return Effect.routeWithDelaysIfUnsupported(state.routes) {
                    $0.dismiss(count: 2)
                }
            default:
                break
            }
            return .none
        }
    ).debug()
