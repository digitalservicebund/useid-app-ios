import Foundation
import ComposableArchitecture
import Analytics

struct SharedCANScreen: ReducerProtocol {
    enum State: Equatable {
        case canIntro(CANIntro.State)
        case canInput(CANInput.State)
        case canIncorrectInput(CANIncorrectInput.State)
        case scanError(ScanError.State)
        
        var swipeToDismissState: SwipeToDismissState {
            switch self {
            case .canIntro(let state): return state.shouldDismiss ? .allowAfterConfirmation() : .block
            case .canInput: return .block
            case .canIncorrectInput: return .allowAfterConfirmation()
            case .scanError: return .allow
            }
        }
    }
    
    enum Action: Equatable {
        case canIntro(CANIntro.Action)
        case canInput(CANInput.Action)
        case canIncorrectInput(CANIncorrectInput.Action)
        case error(ScanError.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.canIntro, action: /Action.canIntro) {
            CANIntro()
        }
        Scope(state: /State.canInput, action: /Action.canInput) {
            CANInput()
        }
        Scope(state: /State.canIncorrectInput, action: /Action.canIncorrectInput) {
            CANIncorrectInput()
        }
        Scope(state: /State.scanError, action: /Action.error) {
            ScanError()
        }
    }
}

extension SharedCANScreen.State: AnalyticsView {
    var route: [String] {
        switch self {
        case .canIntro:
            return ["canIntro"]
        case .canInput:
            return ["canInput"]
        case .canIncorrectInput:
            return ["canIncorrectInput"]
        case .scanError(let state):
            return state.errorType.route
        }
    }
}
