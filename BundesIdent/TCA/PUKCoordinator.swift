import ComposableArchitecture
import TCACoordinators
import Analytics

enum Flow {
    case ident
    case setup
}

struct PUKPINLetter: ReducerProtocol {
    struct State: Equatable {}

    enum Action: Equatable {
        case letterAvailable
        case letterUnavailable
    }

    var body: some ReducerProtocol<State, Action> {
        EmptyReducer()
    }
}

// TODO: Reuse PUKInput for IncorrectPUK as well
struct PUKInput: ReducerProtocol {
    
    var showIncorrect = false
    
    struct State: Equatable {
        @BindingState var digits = ""
        var doneButtonEnabled: Bool {
            digits.count == Constants.PUK_DIGIT_COUNT
        }
    }
    
    enum Action: BindableAction, Equatable {
        case done(puk: String)
        case onAppear
        case binding(BindingAction<State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.digits = ""
                return .none
            default:
                return .none
            }
        }
    }
}

struct PUKScan: ReducerProtocol {
    
    struct State: Equatable {
        var shared: SharedScan.State = .init()
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            .scanEvent(event)
        }
    }
    
    enum Action: Equatable {
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case cancelTapped
        case dismissAlert
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.shared, action: /Action.shared) {
            SharedScan()
        }
    }
}

struct PUKCoordinator: ReducerProtocol {
    
    var flow: Flow
    
    struct State: Equatable {
        var pin: String?
        var can: String?
        var puk: String?
        var attempt: Int = 0
        
        var states: [Route<PUKScreen.State>] = [.root(.pinLetter(.init()))]
        
        var alert: AlertState<Action>?
        
        func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            for (index, state) in states.enumerated().reversed() {
                guard let action = state.screen.transformToLocalAction(event) else { continue }
                return .routeAction(index, action: action)
            }
            return nil
        }
        
        var swipeToDismiss: SwipeToDismissState {
            guard let lastScreen = states.last?.screen else { return .allow }
            return lastScreen.swipeToDismissState
        }
    }
    
    enum Action: Equatable, IndexedRouterAction {
        case routeAction(Int, action: PUKScreen.Action)
        case updateRoutes([Route<PUKScreen.State>])
        case dismissAlert
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .routeAction(_, action: .pinLetter(.letterUnavailable)):
                state.states.push(.missingPINLetter(MissingPINLetter.State()))
                return .none
            case .routeAction(_, action: .pinLetter(.letterAvailable)):
                state.states.push(.pukInput(PUKInput.State()))
                return .none
            case .routeAction:
                return .none
            case .updateRoutes:
                return .none
            case .dismissAlert:
                return .none
            }
        }.forEachRoute {
            PUKScreen()
        }
    }
}

extension PUKCoordinator.State: IndexedRouterState {
    var routes: [Route<PUKScreen.State>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .scan(var state):
                        state.shared.attempt = attempt
                        return .scan(state)
                    default:
                        return screenState
                    }
                }
            }
        }
        set {
            states = newValue.map {
                $0.map { screenState in
                    switch screenState {
                    default:
                        break
                    }
                    return screenState
                }
            }
        }
    }
}

struct PUKScreen: ReducerProtocol {
    
    enum State: Equatable, EIDInteractionHandler {
        case pinLetter(PUKPINLetter.State)
        case pukInput(PUKInput.State)
        case scan(PUKScan.State)
        case pinForgotten(IdentificationCANPINForgotten.State)
        case missingPINLetter(MissingPINLetter.State)
        case pukIncorrectInput(PUKInput.State)
        case error(ScanError.State)
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            switch self {
            case .scan(let state):
                guard let localAction = state.transformToLocalAction(event) else { return nil }
                return .scan(localAction)
            default:
                return nil
            }
        }
        
        var swipeToDismissState: SwipeToDismissState {
            switch self {
            case .pinLetter: return .allow
            case .pukInput: return .allow
            case .scan: return .allowAfterConfirmation()
            case .pinForgotten: return .allow
            case .missingPINLetter: return .allow
            case .pukIncorrectInput: return .allow
            case .error: return .allow
            }
        }
    }
    
    enum Action: Equatable {
        case pinLetter(PUKPINLetter.Action)
        case pukInput(PUKInput.Action)
        case scan(PUKScan.Action)
        case pinForgotten(IdentificationCANPINForgotten.Action)
        case missingPINLetter(MissingPINLetter.Action)
        case pukIncorrectInput(PUKInput.Action)
        case error(ScanError.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.pinLetter, action: /Action.pinLetter) {
            PUKPINLetter()
        }
        Scope(state: /State.pukInput, action: /Action.pukInput) {
            PUKInput()
        }
        Scope(state: /State.scan, action: /Action.scan) {
            PUKScan()
        }
        Scope(state: /State.pinForgotten, action: /Action.pinForgotten) {
            IdentificationCANPINForgotten()
        }
        Scope(state: /State.missingPINLetter, action: /Action.missingPINLetter) {
            MissingPINLetter()
        }
        Scope(state: /State.pukIncorrectInput, action: /Action.pukIncorrectInput) {
            PUKInput(showIncorrect: true)
        }
        Scope(state: /State.error, action: /Action.error) {
            ScanError()
        }
    }
}

extension PUKCoordinator.State: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}

extension PUKScreen.State: AnalyticsView {
    var route: [String] {
        switch self {
        default: return [""] // TODO: Analytics
        }
    }
}
