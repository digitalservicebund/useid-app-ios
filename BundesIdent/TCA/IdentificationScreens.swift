import Foundation
import ComposableArchitecture
import Analytics

struct IdentificationScreen: ReducerProtocol {
    
    enum State: Equatable, EIDInteractionHandler {
        case overview(IdentificationOverview.State)
        case personalPIN(IdentificationPersonalPIN.State)
        case incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State)
        case scan(IdentificationPINScan.State)
        case error(ScanError.State)
        case identificationCANCoordinator(IdentificationCANCoordinator.State)
        case selbstauskunft(WebIdentification.State)
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            switch self {
            case .overview(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .overview(localAction)
            case .scan(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .scan(localAction)
            case .identificationCANCoordinator(let state):
                guard let localAction = state.transformToLocalInteractionHandler(event: event) else {
                    return nil
                }
                return .identificationCANCoordinator(localAction)
            default:
                return nil
            }
        }
        
        var swipeToDismissState: SwipeToDismissState {
            switch self {
            case .overview: return .allowAfterConfirmation()
            case .personalPIN: return .block
            case .scan: return .allowAfterConfirmation()
            // handled by screen reducers
            case .incorrectPersonalPIN: return .allow
            case .error: return .allow
            case .identificationCANCoordinator: return .allow
            case .selbstauskunft: return .allow
            }
        }
    }
    
    enum Action: Equatable {
        case overview(IdentificationOverview.Action)
        case personalPIN(IdentificationPersonalPIN.Action)
        case incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.Action)
        case scan(IdentificationPINScan.Action)
        case error(ScanError.Action)
        case identificationCANCoordinator(IdentificationCANCoordinator.Action)
        case selbstauskunft(WebIdentification.Action)
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
        Scope(state: /State.error, action: /Action.error) {
            ScanError()
        }
        Scope(state: /State.identificationCANCoordinator, action: /Action.identificationCANCoordinator) {
            IdentificationCANCoordinator()
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
        case .personalPIN:
            return ["personalPIN"]
        case .incorrectPersonalPIN:
            return ["incorrectPersonalPIN"]
        case .error(let state):
            return state.errorType.route
        case .identificationCANCoordinator(let state):
            return state.route
        case .selbstauskunft:
            return []
        }
    }
}
