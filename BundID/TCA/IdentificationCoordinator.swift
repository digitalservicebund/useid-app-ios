import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture

struct PINCallback: Identifiable, Equatable {
    
    let id: UUID
    private let callback: (String) -> Void
    
    init(id: UUID, callback: @escaping (String) -> Void) {
        self.id = id
        self.callback = callback
    }
    
    static func == (lhs: PINCallback, rhs: PINCallback) -> Bool {
        return lhs.id == rhs.id
    }
    
    func callAsFunction(_ pin: String) {
        callback(pin)
    }
}

struct IdentificationCoordinatorState: Equatable, IndexedRouterState {
    var tokenURL: String
    var tokenFetch: IdentificationOverviewTokenFetch = .loading
    var pin: String?
    var pinCallback: PINCallback?

#if DEBUG
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    
    var routes: [Route<IdentificationScreenState>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .overview(var state):
                        state.tokenFetch = tokenFetch
                        return .overview(state)
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
                    case .overview(let subState):
                        tokenFetch = subState.tokenFetch
                    default:
                        break
                    }
                    return screenState
                }
            }
        }
    }
    var states: [Route<IdentificationScreenState>]
    
    init(tokenURL: String) {
        self.tokenURL = tokenURL
        self.states = [.root(.overview(IdentificationOverviewState()))]
    }
}

enum IdentificationCoordinatorAction: Equatable, IndexedRouterAction {
    case routeAction(Int, action: IdentificationScreenAction)
    case updateRoutes([Route<IdentificationScreenState>])
    case loadToken
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
#if DEBUG
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

let identificationCoordinatorReducer: Reducer<IdentificationCoordinatorState, IdentificationCoordinatorAction, AppEnvironment> = identificationScreenReducer
    .forEachIndexedRoute(environment: { $0 })
    .withRouteReducer(
        Reducer { state, action, environment in
            enum CancelId {}
            
            switch action {
#if DEBUG
            case .runDebugSequence(let debugSequence):
                state.availableDebugActions = environment.debugIDInteractionManager.runIdentify(debugSequence: debugSequence)
                return .none
#endif
            case .loadToken:
                let publisher: EIDInteractionPublisher
#if DEBUG
                if MOCK_OPENECARD {
                    let debuggableInteraction = environment.debugIDInteractionManager.debuggableIdentify(tokenURL: state.tokenURL)
                    state.availableDebugActions = debuggableInteraction.sequence
                    publisher = debuggableInteraction.publisher
                } else {
                    publisher = environment.idInteractionManager.identify(tokenURL: state.tokenURL)
                }
#else
                publisher = environment.idInteractionManager.identify(tokenURL: state.tokenURL)
#endif
                return publisher
                    .receive(on: environment.mainQueue)
                    .catchToEffect(IdentificationCoordinatorAction.idInteractionEvent)
                    .cancellable(id: CancelId.self, cancelInFlight: true)
                
            case .idInteractionEvent(.success(let event)):
                switch event {
                case .requestAuthenticationRequestConfirmation(let request, let handler):
                    state.tokenFetch = .loaded(IdentificationOverviewLoadedState(id: environment.uuidFactory(), request: request, handler: handler))
                    return .none
                case .requestPIN(remainingAttempts: let remainingAttempts, pinCallback: let callback):
                    state.pinCallback = PINCallback(id: environment.uuidFactory(), callback: callback)
                    return .none
                default:
                    return .none
                }
            case .idInteractionEvent(.failure(let error)):
                state.tokenFetch = .error(IdentifiableError(error))
                return .none
            case .routeAction(_, action: .overview(.identify)):
                if case .loaded = state.tokenFetch { return .none }
                return Effect(value: .loadToken)
            case .routeAction(_, action: .overview(.done)):
                state.routes.push(.personalPIN(IdentificationPersonalPINState()))
                return .none
            case .routeAction(_, action: .personalPIN(.done(pin: let pin))):
                state.pin = pin
                state.routes.push(.scan(IdentificationScanState(tokenURL: state.tokenURL, pin: pin)))
                return .none
            case .routeAction(_, action: .scan(.startScan)):
                guard let pinCallback = state.pinCallback,
                      let pin = state.pin else { return .none }
                pinCallback(pin)
                return .none
            default:
                return .none
            }
        }
    )

struct IdentificationCoordinatorView: View {
    let store: Store<IdentificationCoordinatorState, IdentificationCoordinatorAction>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /IdentificationScreenState.overview,
                        action: IdentificationScreenAction.overview,
                        then: IdentificationOverview.init)
                CaseLet(state: /IdentificationScreenState.personalPIN,
                        action: IdentificationScreenAction.personalPIN,
                        then: IdentificationPersonalPIN.init)
                CaseLet(state: /IdentificationScreenState.scan,
                        action: IdentificationScreenAction.scan,
                        then: IdentificationScan.init)
            }
        }
        .toolbar {
#if DEBUG
            ToolbarItem(placement: .primaryAction) {
                WithViewStore(store) { viewStore in
                    Menu {
                        ForEach(viewStore.availableDebugActions) { sequence in
                            Button(sequence.id) {
                                viewStore.send(.runDebugSequence(sequence))
                            }
                        }
                    } label: {
                        Image(systemName: "wrench")
                    }
                }
            }
#endif
        }
    }
}
