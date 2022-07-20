import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI

struct SetupCoordinatorState: Equatable, IndexedRouterState {
    var transportPIN: String = ""
    var attempt: Int = 0
    var routes: [Route<SetupScreenState>] {
        get {
            states.map {
                $0.map { setupScreenState in
                    switch setupScreenState {
                    case .scan(var scanState):
                        scanState.transportPIN = transportPIN
                        scanState.attempt = attempt
                        return .scan(scanState)
                    default:
                        return setupScreenState
                    }
                }
            }
        }
        set {
            states = newValue
        }
    }
    var states: [Route<SetupScreenState>] = [.root(.intro)]
}

enum SetupCoordinatorAction: Equatable, IndexedRouterAction {
    case routeAction(Int, action: SetupScreenAction)
    case updateRoutes([Route<SetupScreenState>])
    case afterConfirmEnd
}

let setupCoordinatorReducer: Reducer<SetupCoordinatorState, SetupCoordinatorAction, AppEnvironment> = setupScreenReducer
    .forEachIndexedRoute(environment: { $0 })
    .withRouteReducer(
        Reducer { state, action, environment in
            switch action {
            case .routeAction(_, .intro(.chooseNo)):
                state.routes.push(.transportPINIntro)
            case .routeAction(_, .transportPINIntro(.chooseHasPINLetter)):
                state.routes.push(.transportPIN(SetupTransportPINState()))
            case .routeAction(_, .transportPINIntro(.chooseHasNoPINLetter)):
                print("Not implemented")
            case .routeAction(_, .intro(.chooseYes)):
                print("Not implemented")
            case .routeAction(_, .transportPIN(.done(let transportPIN))):
                state.transportPIN = transportPIN
                state.routes.push(.personalPINIntro)
            case .routeAction(_, .personalPINIntro(.continue)):
                state.routes.push(.personalPIN(SetupPersonalPINState()))
            case .routeAction(_, action: .personalPIN(.done(pin: let pin))):
                state.routes.push(.scan(SetupScanState(transportPIN: state.transportPIN, newPIN: pin)))
            case .routeAction(_, action: .scan(.scannedSuccessfully)):
                state.routes.push(.done)
            case .routeAction(_, action: .scan(.error(let errorType))):
                state.routes.push(.error(CardErrorState(errorType: errorType)))
            case .routeAction(_, action: .scan(.wrongTransportPIN(remainingAttempts: let remainingAttempts))):
                state.routes.presentSheet(.incorrectTransportPIN(SetupIncorrectTransportPINState(remainingAttempts: remainingAttempts)))
            case .routeAction(let index, action: .incorrectTransportPIN(.confirmEnd)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return Effect(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: environment.mainQueue)
                    .eraseToEffect()
            case .routeAction(_, action: .incorrectTransportPIN(.done(let transportPIN))):
                state.transportPIN = transportPIN
                state.attempt += 1
                state.routes.dismiss()
            default:
                break
            }
            return .none
        }
    )

struct SetupCoordinatorView: View {
    let store: Store<SetupCoordinatorState, SetupCoordinatorAction>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /SetupScreenState.intro,
                        action: SetupScreenAction.intro,
                        then: SetupIntro.init)
                CaseLet(state: /SetupScreenState.transportPINIntro,
                        action: SetupScreenAction.transportPINIntro,
                        then: SetupTransportPINIntro.init)
                CaseLet(state: /SetupScreenState.transportPIN,
                        action: SetupScreenAction.transportPIN,
                        then: SetupTransportPIN.init)
                CaseLet(state: /SetupScreenState.personalPINIntro,
                        action: SetupScreenAction.personalPINIntro,
                        then: SetupPersonalPINIntro.init)
                CaseLet(state: /SetupScreenState.personalPIN,
                        action: SetupScreenAction.personalPIN,
                        then: SetupPersonalPIN.init)
                CaseLet(state: /SetupScreenState.scan,
                        action: SetupScreenAction.scan,
                        then: SetupScan.init)
                CaseLet(state: /SetupScreenState.done,
                        action: SetupScreenAction.done,
                        then: SetupDone.init)
                CaseLet(state: /SetupScreenState.error,
                        action: SetupScreenAction.error,
                        then: CardError.init)
                CaseLet(state: /SetupScreenState.incorrectTransportPIN,
                        action: SetupScreenAction.incorrectTransportPIN,
                        then: SetupIncorrectTransportPIN.init)
            }
        }
    }
}
