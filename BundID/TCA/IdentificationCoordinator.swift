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
    var attempt: Int = 0
    var requestedPIN = false
    var remainingAttempts: Int?
    var pinCallback: PINCallback?
    var authenticationSuccessful = false

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
#if DEBUG
                        state.availableDebugActions = availableDebugActions
#endif
                        return .overview(state)
                    case .scan(var state):
#if DEBUG
                        state.availableDebugActions = availableDebugActions
#endif
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
    case wrongPIN(remainingAttempts: Int)
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case identifiedSuccessfully
    case error(CardErrorType)
#if DEBUG
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

/*
 Happy path loading token until scanning:
 .authenticationStarted
 .requestAuthenticationRequestConfirmation
 .cardInteractionComplete
 .requestPIN(remainingAttempts: nil)
 .requestCardInsertion
 
 Happy path identification:
 .cardRecognized
 .authenticationSuccessful
 .processCompletedSuccessfully
 
 Wrong pin identification:
 .cardRecognized
 .cardInteractionComplete
 .requestPIN(remainingAttempts: 3)
 .cardRemoved

 Card removed before process finished:
 .cardRecognized
 .authenticationSuccessful
 .cardRemoved // difference from happy path?
 .processCompletedSuccessfully // not really successful
 
 Wrong card:
 .cardInteractionComplete
 .requestPIN(remainingAttempts: nil) // like cancel
 */

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
            case .wrongPIN(remainingAttempts: let remainingAttempts):
                state.remainingAttempts = remainingAttempts
                state.routes.presentSheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPINState(error: .incorrect,
                                                                                                        remainingAttempts: remainingAttempts)))
                return .none
            case .idInteractionEvent(.success(let event)):
                return state.handle(event: event, environment: environment)
            case .idInteractionEvent(.failure(let error)):
                switch error {
                case .cardBlocked:
                    state.routes.push(.error(CardErrorState(errorType: .cardBlocked)))
                case .cardDeactivated:
                    state.routes.push(.error(CardErrorState(errorType: .cardDeactivated)))
                default:
                    state.tokenFetch = .error(IdentifiableError(error))
                    // TODO: We need to check in which state we are, to set the error in the right state
                    // E.g. if state.isScanning or use more advanced cases
                }
                return .none
            case .identifiedSuccessfully:
                state.routes.push(.done(IdentificationDoneState(subject: "TODO"))) // TODO: Fill subject
                return .none
            case .routeAction(_, action: .incorrectPersonalPIN(.done(let pin))):
                state.pin = pin
                state.attempt += 1
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .overview(.identify)):
                if case .loaded = state.tokenFetch { return .none }
                return Effect(value: .loadToken)
            case .routeAction(_, action: .overview(.runDebugSequence(let sequence))),
                    .routeAction(_, action: .scan(.runDebugSequence(let sequence))):
                return Effect(value: .runDebugSequence(sequence))
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
            case .routeAction(let index, action: .incorrectPersonalPIN(.confirmEnd)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return Effect(value: .routeAction(index, action: .incorrectPersonalPIN(.afterConfirmEnd)))
                    .delay(for: 0.65, scheduler: environment.mainQueue)
                    .eraseToEffect()
            default:
                return .none
            }
        }
    )

extension IdentificationCoordinatorState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<IdentificationCoordinatorAction, Never> {
        switch event {
        case .requestAuthenticationRequestConfirmation(let request, let handler):
            tokenFetch = .loaded(IdentificationOverviewLoadedState(id: environment.uuidFactory(), request: request, handler: handler))
            return .none
        case .requestPIN(remainingAttempts: let remainingAttempts, pinCallback: let callback):
            print("Providing PIN with \(remainingAttempts) remaining attempts.")
            pinCallback = PINCallback(id: environment.uuidFactory(), callback: callback)
            
            guard requestedPIN else {
                // This is the first request for the PIN with unknown remainingAttempts.
                // Store callback and wait for pin entry to succeed.
                requestedPIN = true
                return .none
            }
            
            let remainingAttemptsBefore = self.remainingAttempts
            self.remainingAttempts = remainingAttempts
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = remainingAttempts else {
                return .none
            }
            
            // Wrong transport/personal PIN provided again
            if let remainingAttemptsBefore = remainingAttemptsBefore, remainingAttempts < remainingAttemptsBefore {
                return Effect(value: .wrongPIN(remainingAttempts: remainingAttempts))
            } else if remainingAttemptsBefore == nil { // Wrong transport/personal PIN provided first time
                return Effect(value: .wrongPIN(remainingAttempts: remainingAttempts))
            }
            
            return .none
        case .authenticationStarted,
            .cardInteractionComplete,
            .cardRecognized:
            return .none
        case .authenticationSuccessful:
            authenticationSuccessful = true
            return .none
        case .cardRemoved:
            authenticationSuccessful = false
            return .none
        case .processCompletedSuccessfully:
            if authenticationSuccessful {
                return Effect(value: .identifiedSuccessfully)
            } else {
                return .none // TODO: Return error
            }
        default:
            return .none
        }
    }
}

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
                CaseLet(state: /IdentificationScreenState.incorrectPersonalPIN,
                        action: IdentificationScreenAction.incorrectPersonalPIN,
                        then: IdentificationIncorrectPersonalPIN.init)
                CaseLet(state: /IdentificationScreenState.scan,
                        action: IdentificationScreenAction.scan,
                        then: IdentificationScan.init)
                CaseLet(state: /IdentificationScreenState.done,
                        action: IdentificationScreenAction.done,
                        then: IdentificationDone.init)
            }
        }
    }
}
