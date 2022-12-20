import Foundation
import ComposableArchitecture
import Analytics

struct IdentificationScreen: ReducerProtocol {
    
    enum State: Equatable, IDInteractionHandler {
        case overview(IdentificationOverview.State)
        case personalPIN(IdentificationPersonalPIN.State)
        case incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State)
        case scan(IdentificationPINScan.State)
        case error(ScanError.State)
        case identificationCANCoordinator(IdentificationCANCoordinator.State)
        case handOff(IdentificationHandOff.State)
        case done(IdentificationDone.State)
        case share(IdentificationShare.State)
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationScreen.Action? {
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
            case .overview: return .allowAfterConfirmation
            case .personalPIN: return .block
            case .scan: return .allowAfterConfirmation
            // handled by screen reducers
            case .incorrectPersonalPIN: return .allow
            case .error: return .allow
            case .identificationCANCoordinator: return .allow
            case .handOff: return .block
            case .done: return .allow
            case .share: return .allowAfterConfirmation
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
        case handOff(IdentificationHandOff.Action)
        case done(IdentificationDone.Action)
        case share(IdentificationShare.Action)
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
        Scope(state: /State.handOff, action: /Action.handOff) {
            IdentificationHandOff()
        }
        Scope(state: /State.done, action: /Action.done) {
            IdentificationDone()
        }
        Scope(state: /State.share, action: /Action.share) {
            IdentificationShare()
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
        case .handOff:
            return ["handOff"]
        case .share:
            return ["share"]
        case .done:
            return ["done"]
        case .identificationCANCoordinator(let state):
            return state.route
        }
    }
}
