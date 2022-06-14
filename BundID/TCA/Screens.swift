import ComposableArchitecture

enum ScreenState: Equatable {
    case home
    case setupCoordinator(SetupCoordinatorState)
    case identificationCoordinator(IdentificationCoordinatorState)
}

enum ScreenAction: Equatable {
    case home(HomeAction)
    case setupCoordinator(SetupCoordinatorAction)
    case identificationCoordinator(IdentificationCoordinatorAction)
}

let screenReducer = Reducer<ScreenState, ScreenAction, AppEnvironment>.combine(
    setupCoordinatorReducer
        .pullback(
            state: /ScreenState.setupCoordinator,
            action: /ScreenAction.setupCoordinator,
            environment: { $0 }
        ),
    identificationCoordinatorReducer
        .pullback(
            state: /ScreenState.identificationCoordinator,
            action: /ScreenAction.identificationCoordinator,
            environment: { $0 }
        )
)
