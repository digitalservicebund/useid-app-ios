import Foundation
import ComposableArchitecture

enum IdentificationScreenState: Equatable {
    case overview(IdentificationOverviewState)
}

enum IdentificationScreenAction: Equatable {
    case overview(IdentificationOverviewAction)
}

let identificationScreenReducer = Reducer<IdentificationScreenState, IdentificationScreenAction, AppEnvironment>.combine(
    identificationOverviewReducer
        .pullback(
            state: /IdentificationScreenState.overview,
            action: /IdentificationScreenAction.overview,
            environment: { $0 }
        )
)
