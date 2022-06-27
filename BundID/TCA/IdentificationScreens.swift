import Foundation
import ComposableArchitecture

enum IdentificationScreenState: Equatable {
    case overview(IdentificationOverviewState)
    case personalPIN(IdentificationPersonalPINState)
    case scan(IdentificationScanState)
}

enum IdentificationScreenAction: Equatable {
    case overview(IdentificationOverviewAction)
    case personalPIN(IdentificationPersonalPINAction)
    case scan(IdentificationScanAction)
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
    identificationScanReducer
        .pullback(
            state: /IdentificationScreenState.scan,
            action: /IdentificationScreenAction.scan,
            environment: { $0 }
        )
)
