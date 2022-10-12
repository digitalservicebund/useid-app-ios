import ComposableArchitecture
import Analytics

enum ScreenState: Equatable {
    case home(HomeState)
    case setupCoordinator(SetupCoordinatorState)
    case identificationCoordinator(IdentificationCoordinatorState)
}

extension ScreenState: AnalyticsView {
     var route: [String] {
         switch self {
         case .home(let state):
             return state.route
         case .setupCoordinator(let state):
             return ["firstTimeUser"] + state.route
         case .identificationCoordinator(let state):
             return ["identification"] + state.route
         }
     }
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
