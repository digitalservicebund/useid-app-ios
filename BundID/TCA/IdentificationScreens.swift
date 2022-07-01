import Foundation
import ComposableArchitecture

enum IdentificationScreenState: Equatable {
    case overview(IdentificationOverviewState)
    case personalPIN(IdentificationPersonalPINState)
    case incorrectPersonalPIN(IdentificationIncorrectPersonalPINState)
    case scan(IdentificationScanState)
    case error(CardErrorState)
    case done(IdentificationDoneState)
}

enum IdentificationScreenAction: Equatable {
    case overview(IdentificationOverviewAction)
    case personalPIN(IdentificationPersonalPINAction)
    case incorrectPersonalPIN(IdentificationIncorrectPersonalPINAction)
    case scan(IdentificationScanAction)
    case error(CardErrorAction)
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
