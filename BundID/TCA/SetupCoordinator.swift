import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI

struct SetupCoordinatorState: Equatable, IndexedRouterState {
    var transportPIN: String = ""
    var attempt: Int = 0
    var tokenURL: String?
    var needsEndConfirmation: Bool {
        routes.contains {
            switch $0.screen {
            case .transportPIN: return true
            default: return false
            }
        }
    }
    var alert: AlertState<SetupCoordinatorAction>?
    
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
    case end
    case confirmEnd
    case afterConfirmEnd
    case dismissAlert
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
                state.routes.push(.done(SetupDoneState(tokenURL: state.tokenURL)))
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
            case .end:
                state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.title),
                                         message: TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.message),
                                         primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.confirm),
                                                                     action: .send(.confirmEnd)),
                                         secondaryButton: .cancel(TextState(verbatim: L10n.General.cancel)))
            case .confirmEnd:
                return .none
            case .dismissAlert:
                state.alert = nil
                return .none
            default:
                break
            }
            return .none
        }
    )

struct SetupCoordinatorView: View {
    let store: Store<SetupCoordinatorState, SetupCoordinatorAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
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
                .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
            }
            .interactiveDismissDisabled(viewStore.needsEndConfirmation) {
                viewStore.send(.end)
            }
        }
    }
}
