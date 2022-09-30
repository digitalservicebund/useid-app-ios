import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture
import Analytics

protocol IDInteractionHandler {
    associatedtype LocalAction
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> LocalAction?
}

struct IdentificationCoordinatorState: Equatable, IndexedRouterState {
    var tokenURL: URL
    var pin: String?
    var attempt: Int = 0
    var authenticationSuccessful = false
    
    var needsEndConfirmation: Bool {
        routes.contains {
            switch $0.screen {
            case .personalPIN: return true
            default: return false
            }
        }
    }
    var alert: AlertState<IdentificationCoordinatorAction>?

#if PREVIEW
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    
    var routes: [Route<IdentificationScreenState>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .overview(var state):
#if PREVIEW
                        state.availableDebugActions = availableDebugActions
#endif
                        return .overview(state)
                    case .scan(var state):
                        state.pin = pin!
                        state.shared.attempt = attempt
#if PREVIEW
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
                    default:
                        break
                    }
                    return screenState
                }
            }
        }
    }
    var states: [Route<IdentificationScreenState>]
    
    func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationCoordinatorAction? {
        for (index, state) in states.enumerated().reversed() {
            guard let action = state.screen.transformToLocalAction(event) else { continue }
            return .routeAction(index, action: action)
        }
        return nil
    }
}

extension IdentificationCoordinatorState: AnalyticsView {
     var route: [String] {
         states.last?.screen.route ?? []
     }
 }

extension IdentificationCoordinatorState {
    init(tokenURL: URL) {
        self.tokenURL = tokenURL
        self.states = [.root(.overview(.loading(IdentificationOverviewLoadingState())))]
    }
}

enum IdentificationCoordinatorAction: Equatable, IndexedRouterAction {
    case routeAction(Int, action: IdentificationScreenAction)
    case updateRoutes([Route<IdentificationScreenState>])
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case scanError(ScanErrorState)
    case end
    case confirmEnd
    case afterConfirmEnd
    case dismissAlert
    case dismiss
#if PREVIEW
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
 .authenticationSuccessful (optional)
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
#if PREVIEW
            case .runDebugSequence(let debugSequence):
                state.availableDebugActions = environment.debugIDInteractionManager.runIdentify(debugSequence: debugSequence)
                return .none
#endif
            case .routeAction(_, action: .scan(.wrongPIN(remainingAttempts: let remainingAttempts))):
                state.routes.presentSheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPINState(error: .incorrect,
                                                                                                        remainingAttempts: remainingAttempts)))
                return .none
            case .idInteractionEvent(let result):
                guard let localAction = state.transformToLocalInteractionHandler(event: result) else {
                    fatalError("TODO: This should be handled be sent to error tracking and silently ignored.")
                }
                return Effect(value: localAction)
            case .routeAction(_, action: .incorrectPersonalPIN(.done(let pin))):
                state.pin = pin
                state.attempt += 1
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .overview(.loading(.identify))):
                let publisher: EIDInteractionPublisher
#if PREVIEW
                if MOCK_OPENECARD {
                    let debuggableInteraction = environment.debugIDInteractionManager.debuggableIdentify(tokenURL: state.tokenURL)
                    state.availableDebugActions = debuggableInteraction.sequence
                    publisher = debuggableInteraction.publisher
                } else {
                    publisher = environment.idInteractionManager.identify(tokenURL: state.tokenURL, nfcMessages: .identification)
                }
#else
                publisher = environment.idInteractionManager.identify(tokenURL: state.tokenURL, nfcMessages: .identification)
#endif
                return publisher
                    .receive(on: environment.mainQueue)
                    .catchToEffect(IdentificationCoordinatorAction.idInteractionEvent)
                    .cancellable(id: CancelId.self, cancelInFlight: true)
#if PREVIEW
            case .routeAction(_, action: .overview(.loading(.runDebugSequence(let sequence)))),
                    .routeAction(_, action: .scan(.runDebugSequence(let sequence))):
                return Effect(value: .runDebugSequence(sequence))
#endif
            case .routeAction(_, action: .overview(.loaded(.callbackReceived(let request, let callback)))):
                state.routes.push(.personalPIN(IdentificationPersonalPINState(request: request, callback: callback)))
                return .none
            case .routeAction(_, action: .personalPIN(.done(request: let request, pin: let pin, pinCallback: let pinCallback))):
                state.pin = pin
                state.routes.push(
                    .scan(IdentificationScanState(request: request,
                                                  pin: pin,
                                                  pinCallback: pinCallback))
                )
                return .none
            case .routeAction(_, action: .scan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
                return .none
            case .routeAction(_, action: .scan(.shared(.showHelp))):
                state.routes.presentSheet(.error(ScanErrorState(errorType: .help, retry: true)))
                return .none
            case .routeAction(_, action: .error(.retry)):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .error(.end)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return Effect(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: environment.mainQueue)
                    .eraseToEffect()
                
            case .routeAction(let index, action: .incorrectPersonalPIN(.confirmEnd)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return Effect(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: environment.mainQueue)
                    .eraseToEffect()
                
            case .end:
                state.alert = AlertState(title: TextState(verbatim: L10n.Identification.ConfirmEnd.title),
                                         message: TextState(verbatim: L10n.Identification.ConfirmEnd.message),
                                         primaryButton: .destructive(TextState(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                                                     action: .send(.confirmEnd)),
                                         secondaryButton: .cancel(TextState(verbatim: L10n.Identification.ConfirmEnd.deny)))
                return .none
            case .dismissAlert:
                state.alert = nil
                return .none
            case .dismiss:
                state.routes.dismiss()
                return .none
            default:
                return .none
            }
        }
    )

struct IdentificationCoordinatorView: View {
    let store: Store<IdentificationCoordinatorState, IdentificationCoordinatorAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
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
                        CaseLet(state: /IdentificationScreenState.error,
                                action: IdentificationScreenAction.error,
                                then: ScanError.init)
                    }
                }
                .navigationBarHidden(false)
                .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
            }
            .interactiveDismissDisabled(viewStore.needsEndConfirmation) {
                viewStore.send(.end)
            }
        }
    }
}
