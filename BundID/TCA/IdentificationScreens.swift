import Foundation
import ComposableArchitecture

enum IdentificationScreenState: Equatable, IDInteractionHandler {
    case overview(IdentificationOverviewState)
    case personalPIN(IdentificationPersonalPINState)
    case incorrectPersonalPIN(IdentificationIncorrectPersonalPINState)
    case scan(IdentificationScanState)
    case cardError(CardErrorState)
    case done(IdentificationDoneState)
    
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationScreenAction? {
        switch self {
        case .overview(let state):
            guard let localAction = state.transformToLocalAction(event) else { return nil }
            return .overview(localAction)
        case .scan(let state):
            guard let localAction = state.transformToLocalAction(event) else { return nil }
            return .scan(localAction)
        default:
            return nil
        }
    }
}

enum IdentificationScreenAction: Equatable {
    case overview(IdentificationOverviewAction)
    case personalPIN(IdentificationPersonalPINAction)
    case incorrectPersonalPIN(IdentificationIncorrectPersonalPINAction)
    case scan(IdentificationScanAction)
    case cardError(CardErrorAction)
    case done(IdentificationDoneAction)
}

let identificationScreenReducer = Reducer<IdentificationScreenState, IdentificationScreenAction, AppEnvironment>.combine(
    identificationOverviewReducer
        .pullback(
            state: /IdentificationScreenState.overview,
            action: /IdentificationScreenAction.overview,
            environment: { $0 }
        ),
    identificationPersonalPINReducer
        .pullback(
            state: /IdentificationScreenState.personalPIN,
            action: /IdentificationScreenAction.personalPIN,
            environment: { $0 }
        ),
    identificationIncorrectPersonalPINReducer
        .pullback(
            state: /IdentificationScreenState.incorrectPersonalPIN,
            action: /IdentificationScreenAction.incorrectPersonalPIN,
            environment: { $0 }
        ),
    identificationScanReducer
        .pullback(
            state: /IdentificationScreenState.scan,
            action: /IdentificationScreenAction.scan,
            environment: { $0 }
        )
)
