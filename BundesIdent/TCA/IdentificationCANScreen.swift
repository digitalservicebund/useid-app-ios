import Foundation
import ComposableArchitecture
import Analytics

struct IdentificationCANScreen: ReducerProtocol {
    
    enum State: Equatable, IDInteractionHandler {
        case canScan(IdentificationCANScan.State)
        case canPINForgotten(IdentificationCANPINForgotten.State)
        case canOrderNewPIN(IdentificationCANOrderNewPIN.State)
        case canIntro(CANIntro.State)
        case canInput(CANInput.State)
        case canPersonalPINInput(IdentificationCANPersonalPINInput.State)
        case canIncorrectInput(CANIncorrectInput.State)
        case error(ScanError.State)
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> Action? {
            switch self {
            case .canScan(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .canScan(localAction)
            default:
                return nil
            }
        }
        
        var swipeToDismissState: SwipeToDismissState {
            switch self {
            case .canScan: return .allowAfterConfirmation()
            case .canPINForgotten: return .allowAfterConfirmation()
            case .canOrderNewPIN: return .block
            case .canIntro(let state):
                return state.isRootOfCANFlow ? .allowAfterConfirmation() : .block
            case .canInput: return .block
            case .canPersonalPINInput: return .block
            case .canIncorrectInput: return .allowAfterConfirmation()
            case .error: return .allow
            }
        }
    }
    
    enum Action: Equatable {
        case canScan(IdentificationCANScan.Action)
        case canPINForgotten(IdentificationCANPINForgotten.Action)
        case orderNewPIN(IdentificationCANOrderNewPIN.Action)
        case canIntro(CANIntro.Action)
        case canInput(CANInput.Action)
        case canPersonalPINInput(IdentificationCANPersonalPINInput.Action)
        case canIncorrectInput(CANIncorrectInput.Action)
        case error(ScanError.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.canScan, action: /Action.canScan) {
            IdentificationCANScan()
        }
        Scope(state: /State.canPINForgotten, action: /Action.canPINForgotten) {
            IdentificationCANPINForgotten()
        }
        Scope(state: /State.canOrderNewPIN, action: /Action.orderNewPIN) {
            IdentificationCANOrderNewPIN()
        }
        Scope(state: /State.canIntro, action: /Action.canIntro) {
            CANIntro()
        }
        Scope(state: /State.canInput, action: /Action.canInput) {
            CANInput()
        }
        
        Scope(state: /State.canPersonalPINInput, action: /Action.canPersonalPINInput) {
            IdentificationCANPersonalPINInput()
        }
        Scope(state: /State.canIncorrectInput, action: /Action.canIncorrectInput) {
            CANIncorrectInput()
        }
        Scope(state: /State.error, action: /Action.error) {
            ScanError()
        }
    }
}

extension IdentificationCANScreen.State: AnalyticsView {
    var route: [String] {
        switch self {
        case .canScan:
            return ["canScan"]
        case .canPINForgotten:
            return ["canPINForgotten"]
        case .canOrderNewPIN:
            return ["canOrderNewPIN"]
        case .canIntro:
            return ["canIntro"]
        case .canInput:
            return ["canInput"]
        case .canPersonalPINInput:
            return ["canPersonalPINInput"]
        case .canIncorrectInput:
            return ["canIncorrectInput"]
        case .error(let state):
            return state.errorType.route
        }
    }
}
