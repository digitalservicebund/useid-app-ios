import Foundation
import ComposableArchitecture
import Analytics

struct IdentificationScreen: ReducerProtocol {
    
    enum State: Equatable, IDInteractionHandler {
        case overview(IdentificationOverview.State)
        case personalPIN(IdentificationPersonalPIN.State)
        case incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State)
        case canPINForgotten(IdentificationCANPINForgotten.State)
        case canOrderNewPIN(IdentificationCANOrderNewPIN.State)
        case canIntro(IdentificationCANIntro.State)
        case canInput(IdentificationCANInput.State)
        case canPersonalPINInput(IdentificationCANPersonalPINInput.State)
        case canIncorrectInput(IdentificationCANIncorrectInput.State)
        case scan(IdentificationPINScan.State)
        case canScan(IdentificationCANScan.State)
        case error(ScanError.State)
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationScreen.Action? {
            switch self {
            case .overview(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .overview(localAction)
            case .scan(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .scan(localAction)
            case .canScan(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .canScan(localAction)
            default:
                return nil
            }
        }
        
        var swipeToDismissState: SwipeToDismissState {
            switch self {
            case .overview: return .allowAfterConfirmation
            case .personalPIN: return .block
            case .scan: return .allowAfterConfirmation
            case .canScan: return .allowAfterConfirmation
                // handled by screen reducers
            case .incorrectPersonalPIN: return .allow
            case .canPINForgotten: return .allowAfterConfirmation
            case .canOrderNewPIN: return .block
            case .canIntro(let state):
                return state.shouldDismiss ? .allowAfterConfirmation : .block
            case .canInput: return .block
            case .canPersonalPINInput: return .block
            case .canIncorrectInput: return .allowAfterConfirmation
            case .error: return .allow
            }
        }
    }
    
    enum Action: Equatable {
        case overview(IdentificationOverview.Action)
        case personalPIN(IdentificationPersonalPIN.Action)
        case incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.Action)
        case scan(IdentificationPINScan.Action)
        case canScan(IdentificationCANScan.Action)
        case canPINForgotten(IdentificationCANPINForgotten.Action)
        case orderNewPIN(IdentificationCANOrderNewPIN.Action)
        case canIntro(IdentificationCANIntro.Action)
        case canInput(IdentificationCANInput.Action)
        case canPersonalPINInput(IdentificationCANPersonalPINInput.Action)
        case canIncorrectInput(IdentificationCANIncorrectInput.Action)
        case error(ScanError.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.overview, action: /Action.overview) {
            IdentificationOverview()
        }
        Scope(state: /State.personalPIN, action: /Action.personalPIN) {
            IdentificationPersonalPIN()
        }
        Scope(state: /IdentificationScreen.State.incorrectPersonalPIN,
              action: /IdentificationScreen.Action.incorrectPersonalPIN) {
            IdentificationIncorrectPersonalPIN()
        }
        Scope(state: /State.scan, action: /Action.scan) {
            IdentificationPINScan()
        }
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
            IdentificationCANIntro()
        }
        Scope(state: /State.canInput, action: /Action.canInput) {
            IdentificationCANInput()
        }
        
        Scope(state: /State.canPersonalPINInput, action: /Action.canPersonalPINInput) {
            IdentificationCANPersonalPINInput()
        }
        Scope(state: /State.canIncorrectInput, action: /Action.canIncorrectInput) {
            IdentificationCANIncorrectInput()
        }
        Scope(state: /State.error, action: /Action.error) {
            ScanError()
        }
    }
}

extension IdentificationScreen.State: AnalyticsView {
    var route: [String] {
        switch self {
        case .overview:
            return ["attributes"]
        case .scan:
            return ["scan"]
        case .canScan:
            return ["canScan"]
        case .personalPIN:
            return ["personalPIN"]
        case .incorrectPersonalPIN:
            return ["incorrectPersonalPIN"]
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
