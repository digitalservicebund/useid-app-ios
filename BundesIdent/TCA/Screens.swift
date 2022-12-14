import ComposableArchitecture
import Analytics

struct Screen: ReducerProtocol {
    enum State: Equatable {
        case home(Home.State)
        case setupCoordinator(SetupCoordinator.State)
        case identificationCoordinator(IdentificationCoordinator.State)
    }
    
    enum Action: Equatable {
        case home(Home.Action)
        case setupCoordinator(SetupCoordinator.Action)
        case identificationCoordinator(IdentificationCoordinator.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
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
        case .home(let state):
            return state.route
        case .setupCoordinator(let state):
            return ["firstTimeUser"] + state.route
        case .identificationCoordinator(let state):
            return ["identification"] + state.route
        }
    }
}
