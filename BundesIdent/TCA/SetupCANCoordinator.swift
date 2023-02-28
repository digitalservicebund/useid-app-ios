import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture
import Analytics

struct CANAndChangedPINCallbackPayload: Equatable {
    let can: String
    let oldPIN: String
    let newPIN: String
}

typealias CANAndChangedPINCallback = IdentifiableCallback<CANAndChangedPINCallbackPayload>

struct ChangedPINCallbackPayload: Equatable {
    let oldPIN: String
    let newPIN: String
}

typealias ChangedPINCallback = IdentifiableCallback<ChangedPINCallbackPayload>

enum SetupCANCoordinatorError: CustomNSError {
    case canNilWhenTriedScan
    case pinNilWhenTriedScan
    case canIntroStateNotInRoutes
    case pinCANCallbackNilWhenTriedScan
    case noScreenToHandleEIDInteractionEvents
}

struct SetupCANCoordinator: ReducerProtocol {
    
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    
    struct State: Equatable, IndexedRouterState {
        
        var pin: String
        var transportPIN: String?
        var can: String?
        var oldTransportPIN: String
        var initialCANAndChangedPINCallback: CANAndChangedPINCallback
        var tokenURL: URL?
        var authenticationSuccessful = false
        var attempt: Int
        
        var swipeToDismiss: SwipeToDismissState {
            guard let lastScreen = states.last?.screen else { return .allow }
            return lastScreen.swipeToDismissState
        }
        
        var alert: AlertState<Action>?
#if PREVIEW
        var availableDebugActions: [ChangePINDebugSequence] = []
#endif
        var states: [Route<SetupCANScreen.State>]
        
        typealias LocalAction = Action
        
        func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, IDCardInteractionError>) -> Action? {
            for (index, state) in states.enumerated().reversed() {
                guard let action = state.screen.transformToLocalAction(event) else { continue }
                return .routeAction(index, action: action)
            }
            return nil
        }
    }
    
    indirect enum Action: Equatable, IndexedRouterAction {
        case routeAction(Int, action: SetupCANScreen.Action)
        case updateRoutes([Route<SetupCANScreen.State>])
        case scanError(ScanError.State)
        case swipeToDismiss
        case afterConfirmEnd
        case dismissAlert
        case dismiss
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .routeAction(_, action: .canConfirmTransportPIN(.confirm)):
                state.routes.push(.canAlreadySetup(.init(tokenURL: state.tokenURL)))
                return .none
            case .routeAction(_, action: .canConfirmTransportPIN(.edit)):
                state.routes.push(.canIntro(.init(shouldDismiss: false)))
                return .none
            case .routeAction(_, action: .canAlreadySetup(.missingPersonalPIN)):
                state.routes.push(.missingPIN(.init()))
                return .none
            case .routeAction(_, action: .canAlreadySetup(.done)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canIntro(.showInput(let shouldDismiss))):
                state.routes.push(.canInput(CANInput.State(pushesToPINEntry: !shouldDismiss)))
                return .none
            case .routeAction(_, action: .canIntro(.end)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canInput(.done(can: let can, pushesToPINEntry: let pushesToPINEntry))):
                state.can = can
                if pushesToPINEntry {
                    state.routes.push(.canTransportPINInput(.init(attempts: 1)))
                } else if let transportPIN = state.transportPIN {
                    state.routes.push(
                        .canScan(SetupCANScan.State(transportPIN: transportPIN,
                                                    newPIN: state.pin,
                                                    can: can,
                                                    canAndChangedPINCallback: state.initialCANAndChangedPINCallback,
                                                    shared: SharedScan.State(showInstructions: false)))
                    )
                } else {
                    issueTracker.capture(error: IdentificationCANCoordinatorError.pinNilWhenTriedScan)
                    logger.error("Transport PIN or new PIN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                return .none
            case .routeAction(_, action: .canTransportPINInput(.done(transportPIN: let transportPIN))):
                state.transportPIN = transportPIN
                guard let can = state.can else {
                    issueTracker.capture(error: IdentificationCANCoordinatorError.canNilWhenTriedScan)
                    logger.error("CAN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                state.routes.push(
                    .canScan(SetupCANScan.State(transportPIN: transportPIN,
                                                newPIN: state.pin,
                                                can: can,
                                                canAndChangedPINCallback: state.initialCANAndChangedPINCallback,
                                                shared: SharedScan.State(showInstructions: false)))
                )
                
                return .none
            case .routeAction(_, action: .canScan(.incorrectCAN)):
                state.routes.presentSheet(.canIncorrectInput(CANIncorrectInput.State()))
                return .none
            case .routeAction(_, action: .canIncorrectInput(.done(can: let newCAN))):
                state.can = newCAN
                state.attempt += 1
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .canIncorrectInput(.end)):
                guard let index = state.routes.firstIndex(where: { route in
                    if case .canIntro = route.screen {
                        return true
                    }
                    return false
                }) else {
                    issueTracker.capture(error: SetupCANCoordinatorError.canIntroStateNotInRoutes)
                    logger.error("CanIntroState not found in routes")
                    return Effect(value: .dismiss)
                }
                return Effect.routeWithDelaysIfUnsupported(state.routes, scheduler: mainQueue) {
                    $0.dismiss()
                    $0.popTo(index: index)
                }
            case .routeAction(_, action: .canScan(.scannedSuccessfully)):
                let setupCoordinatorState = SetupCoordinator.State(tokenURL: state.tokenURL,
                                                                   states: [
                                                                       .root(.done(SetupDone.State(tokenURL: state.tokenURL)))
                                                                   ])
                state.routes.push(.setupCoordinator(setupCoordinatorState))
                return .none
            case .routeAction(_, action: .canScan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
                return .none
            case .routeAction(_, action: .canScan(.shared(.showHelp))):
                state.routes.presentSheet(.error(ScanError.State(errorType: .help, retry: true)))
                return .none
            case .routeAction(_, action: .error(.retry)):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .error(.end)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return Effect(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: mainQueue)
                    .eraseToEffect()
            case .swipeToDismiss:
                switch state.swipeToDismiss {
                case .allow:
                    return .none
                case .block:
                    return .none
                case .allowAfterConfirmation:
                    state.alert = AlertState(title: TextState(verbatim: L10n.Identification.ConfirmEnd.title),
                                             message: TextState(verbatim: L10n.Identification.ConfirmEnd.message),
                                             primaryButton: .destructive(TextState(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                                                         action: .send(.dismiss)),
                                             secondaryButton: .cancel(TextState(verbatim: L10n.Identification.ConfirmEnd.deny)))
                    return .none
                }
            case .dismissAlert:
                state.alert = nil
                return .none
            default:
                return .none
            }
        }.forEachRoute {
            SetupCANScreen()
        }
    }
}

extension SetupCANCoordinator.State: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}

extension SetupCANCoordinator.State {
    
    init(oldTransportPIN: String, transportPIN: String?, pin: String, callback: CANAndChangedPINCallback, attempt: Int, goToCanIntroScreen: Bool) {
        self.oldTransportPIN = oldTransportPIN
        self.transportPIN = transportPIN
        self.pin = pin
        initialCANAndChangedPINCallback = callback
        self.attempt = attempt
        
        if goToCanIntroScreen {
            states = [.root(.canIntro(.init(shouldDismiss: true)))]
        } else {
            states = [
                .root(.canConfirmTransportPIN(SetupCANConfirmTransportPIN.State(transportPIN: oldTransportPIN)))
            ]
        }
    }
    
    var routes: [Route<SetupCANScreen.State>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .canScan(var state):
                        if let transportPIN {
                            state.transportPIN = transportPIN
                        }
                        if let can {
                            state.can = can
                        }
                        state.newPIN = pin
                        state.shared.attempt = attempt
                        return .canScan(state)
                    default:
                        return screenState
                    }
                }
            }
        }
        set {
            states = newValue.map {
                $0.map { screenState in
                    switch screenState {
                    default:
                        break
                    }
                    return screenState
                }
            }
        }
    }
}

struct SetupCANCoordinatorView: View {
    let store: StoreOf<SetupCANCoordinator>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            TCARouter(store) { screen in
                SwitchStore(screen) {
                    CaseLet(state: /SetupCANScreen.State.canConfirmTransportPIN,
                            action: SetupCANScreen.Action.canConfirmTransportPIN,
                            then: SetupCANConfirmTransportPINView.init)
                    CaseLet(state: /SetupCANScreen.State.canAlreadySetup,
                            action: SetupCANScreen.Action.canAlreadySetup,
                            then: SetupCANAlreadySetupView.init)
                    CaseLet(state: /SetupCANScreen.State.missingPIN,
                            action: SetupCANScreen.Action.missingPIN,
                            then: MissingPINLetterView.init)
                    CaseLet(state: /SetupCANScreen.State.canIntro,
                            action: SetupCANScreen.Action.canIntro,
                            then: CANIntroView.init)
                    CaseLet(state: /SetupCANScreen.State.canInput,
                            action: SetupCANScreen.Action.canInput,
                            then: CANInputView.init)
                    CaseLet(state: /SetupCANScreen.State.canTransportPINInput,
                            action: SetupCANScreen.Action.canTransportPINInput,
                            then: SetupTransportPINView.init)
                    CaseLet(state: /SetupCANScreen.State.canIncorrectInput,
                            action: SetupCANScreen.Action.canIncorrectInput,
                            then: CANIncorrectInputView.init)
                    CaseLet(state: /SetupCANScreen.State.canScan,
                            action: SetupCANScreen.Action.canScan,
                            then: SetupCANScanView.init)
                    CaseLet(state: /SetupCANScreen.State.error,
                            action: SetupCANScreen.Action.error,
                            then: ScanErrorView.init)
                    Default {
                        SwitchStore(screen) {
                            CaseLet(state: /SetupCANScreen.State.setupCoordinator,
                                    action: SetupCANScreen.Action.setupCoordinator,
                                    then: SetupCoordinatorView.init)
                        }
                    }
                }
            }
            .navigationBarHidden(false)
            .alert(store.scope(state: \.alert), dismiss: SetupCANCoordinator.Action.dismissAlert)
            .interactiveDismissDisabled(viewStore.swipeToDismiss != .allow) {
                viewStore.send(.swipeToDismiss)
            }
        }
    }
    
}
