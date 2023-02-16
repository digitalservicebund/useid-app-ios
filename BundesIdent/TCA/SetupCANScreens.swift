import Foundation
import SwiftUI
import ComposableArchitecture
import Analytics

struct SetupCANScreen: ReducerProtocol {
    
    enum State: Equatable, IDInteractionHandler {
        case canAlreadySetup(SetupCANAlreadySetup.State)
        case canConfirmTransportPIN(SetupCANConfirmTransportPIN.State)
        case missingPIN(MissingPINLetter.State)
        case canIntro(CANIntro.State)
        case canInput(CANInput.State)
        case canTransportPINInput(SetupTransportPIN.State)
        case canScan(SetupCANScan.State)
        case canIncorrectInput(CANIncorrectInput.State)
        case error(ScanError.State)
        case setupCoordinator(SetupCoordinator.State)
        
        var swipeToDismissState: SwipeToDismissState {
            switch self {
            case .canConfirmTransportPIN: return .allowAfterConfirmation()
            case .canAlreadySetup: return .block
            case .missingPIN: return .block
            case .canIntro(let state):
                return state.shouldDismiss ? .allowAfterConfirmation() : .block
            case .canInput: return .block
            case .canTransportPINInput: return .block
            case .canScan: return .block
            case .canIncorrectInput: return .allowAfterConfirmation()
            case .error: return .allow
            case .setupCoordinator: return .allow
            }
        }
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> Action? {
            switch self {
            case .canScan(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .canScan(localAction)
            case .setupCoordinator(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .setupCoordinator(localAction)
            default:
                return nil
            }
        }
    }
    
    enum Action: Equatable {
        case canAlreadySetup(SetupCANAlreadySetup.Action)
        case canConfirmTransportPIN(SetupCANConfirmTransportPIN.Action)
        case missingPIN(MissingPINLetter.Action)
        case canIntro(CANIntro.Action)
        case canInput(CANInput.Action)
        case canTransportPINInput(SetupTransportPIN.Action)
        case canScan(SetupCANScan.Action)
        case canIncorrectInput(CANIncorrectInput.Action)
        case error(ScanError.Action)
        case setupCoordinator(SetupCoordinator.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.canConfirmTransportPIN, action: /Action.canConfirmTransportPIN) {
            SetupCANConfirmTransportPIN()
        }
        Scope(state: /State.canAlreadySetup, action: /Action.canAlreadySetup) {
            SetupCANAlreadySetup()
        }
        Scope(state: /State.missingPIN, action: /Action.missingPIN) {
            MissingPINLetter()
        }
        Scope(state: /State.canIntro, action: /Action.canIntro) {
            CANIntro()
        }
        Scope(state: /State.canInput, action: /Action.canInput) {
            CANInput()
        }
        Scope(state: /State.canTransportPINInput, action: /Action.canTransportPINInput) {
            SetupTransportPIN()
        }
        Scope(state: /State.canScan, action: /Action.canScan) {
            SetupCANScan()
        }
        Scope(state: /State.canIncorrectInput, action: /Action.canIncorrectInput) {
            CANIncorrectInput()
        }
        Scope(state: /State.error, action: /Action.error) {
            ScanError()
        }
        Scope(state: /State.setupCoordinator, action: /Action.setupCoordinator) {
            SetupCoordinator()
        }
    }
}

extension SetupCANScreen.State: AnalyticsView {
    var route: [String] {
        switch self {
        case .canConfirmTransportPIN:
            return ["canConfirmTransportPIN"]
        case .canAlreadySetup:
            return ["canAlreadySetup"]
        case .missingPIN:
            return ["canMissingPIN"]
        case .canIntro:
            return ["canIntro"]
        case .canInput:
            return ["canInput"]
        case .canTransportPINInput:
            return ["canTransportPINInput"]
        case .canScan:
            return ["canScan"]
        case .canIncorrectInput:
            return ["canIncorrectInput"]
        case .error(let state):
            return state.errorType.route
        case .setupCoordinator(let state):
            return state.route
        }
    }
}
