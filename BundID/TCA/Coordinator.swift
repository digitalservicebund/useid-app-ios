import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

// TODO: SetupCoordinatorState
struct CoordinatorState: Equatable, IndexedRouterState {
    var transportPIN: String = ""
    var attempt: Int = 0
    var routes: [Route<ScreenState>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .setupScan(var setupScanState):
                        setupScanState.transportPIN = transportPIN
                        setupScanState.attempt = attempt
                        return .setupScan(setupScanState)
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
    var states: [Route<ScreenState>]
}

// TODO: SetupCoordinatorAction
enum CoordinatorAction: IndexedRouterAction {
    case routeAction(Int, action: ScreenAction)
    case updateRoutes([Route<ScreenState>])
}

// TODO: setupCoordinatorReducer with State and Action adjusted
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
            case .routeAction(_, action: .setupScan(.error(let errorType))):
                state.routes.push(.setupError(SetupErrorState(errorType: errorType)))
            case .routeAction(_, action: .setupError(.done)):
                state.routes.dismiss()
            case .routeAction(_, action: .setupScan(.wrongTransportPIN(remainingAttempts: let remainingAttempts))):
                state.routes.presentSheet(.setupIncorrectTransportPIN(SetupIncorrectTransportPINState(remainingAttempts: remainingAttempts)))
            case .routeAction(_, action: .setupDone(.done)):
                state.routes.dismiss()
            case .routeAction(_, action: .setupIncorrectTransportPIN(.done(let transportPIN))):
                state.transportPIN = transportPIN
                state.attempt += 1
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

// TODO: Introduce new coordinatorReducer with State and Action which handles: HomeScreen, SetupFlowCoordinator, IdentificationCoordinator
