import ComposableArchitecture

enum ScreenState: Equatable {
    case home
    case setupCoordinator(SetupCoordinatorState)
}

enum ScreenAction: Equatable {
    case home(HomeAction)
    case setupCoordinator(SetupCoordinatorAction)
}

let screenReducer = Reducer<ScreenState, ScreenAction, AppEnvironment>.combine(
    setupCoordinatorReducer
        .pullback(
            state: /ScreenState.setupCoordinator,
            action: /ScreenAction.setupCoordinator,
            environment: { $0 }
        )
)
