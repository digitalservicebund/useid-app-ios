import Foundation
import SwiftUI
import ComposableArchitecture
import Analytics

struct SetupCANScreen: ReducerProtocol {
    
    enum State: Equatable, IDInteractionHandler {
        case canAlreadySetup(SetupCANAlreadySetup.State)
        case canConfirmTransportPIN(SetupCANConfirmTransportPIN.State)
        case missingPIN(MissingPINLetter.State)
        case canTransportPINInput(SetupTransportPIN.State)
        case canScan(SetupCANScan.State)
        case setupCoordinator(SetupCoordinator.State)
        case shared(SharedCANScreen.State)
        
        var swipeToDismissState: SwipeToDismissState {
            switch self {
            case .canConfirmTransportPIN: return .allowAfterConfirmation()
            case .canAlreadySetup: return .block
            case .missingPIN: return .block
            case .canTransportPINInput: return .block
            case .canScan: return .block
            case .setupCoordinator: return .allow
            case .shared(let state): return state.swipeToDismissState
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
            case .shared(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .shared(localAction)
            default:
                return nil
            }
        }
    }
    
    indirect enum Action: Equatable {
        case canAlreadySetup(SetupCANAlreadySetup.Action)
        case canConfirmTransportPIN(SetupCANConfirmTransportPIN.Action)
        case missingPIN(MissingPINLetter.Action)
        case canTransportPINInput(SetupTransportPIN.Action)
        case canScan(SetupCANScan.Action)
        case setupCoordinator(SetupCoordinator.Action)
        case shared(SharedCANScreen.Action)
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
        Scope(state: /State.canTransportPINInput, action: /Action.canTransportPINInput) {
            SetupTransportPIN()
        }
        Scope(state: /State.canScan, action: /Action.canScan) {
            SetupCANScan()
        }
        Scope(state: /State.setupCoordinator, action: /Action.setupCoordinator) {
            SetupCoordinator()
        }
        Scope(state: /State.shared, action: /Action.shared) {
            SharedCANScreen()
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
        case .canTransportPINInput:
            return ["canTransportPINInput"]
        case .canScan:
            return ["canScan"]
        case .setupCoordinator(let state):
            return state.route
        case .shared(let state):
            return state.route
        }
    }
}
