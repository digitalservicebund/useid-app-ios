import ComposableArchitecture
import Analytics

struct Screen: ReducerProtocol {
    enum State: Equatable {
        case launch
        case home(Home.State)
        case setupCoordinator(SetupCoordinator.State)
        case identificationCoordinator(IdentificationCoordinator.State)
    }
    
    enum Action: Equatable {
        case launch(Launch.Action)
        case home(Home.Action)
        case setupCoordinator(SetupCoordinator.Action)
        case identificationCoordinator(IdentificationCoordinator.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.launch, action: /Action.launch) {
            Launch()
        }
        Scope(state: /State.home, action: /Action.home) {
            Home()
        }
        Scope(state: /State.setupCoordinator, action: /Action.setupCoordinator) {
            SetupCoordinator()
        }
        Scope(state: /State.identificationCoordinator, action: /Action.identificationCoordinator) {
            IdentificationCoordinator()
        }
    }
}

extension Screen.State: AnalyticsView {
    var route: [String] {
        switch self {
        case .launch:
            return []
        case .home(let state):
            return state.route
        case .setupCoordinator(let state):
            return ["firstTimeUser"] + state.route
        case .identificationCoordinator(let state):
            return ["identification"] + state.route
        }
    }
}
