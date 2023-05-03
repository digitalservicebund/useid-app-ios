import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture
import Analytics

protocol EIDInteractionHandler {
    associatedtype LocalAction
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> LocalAction?
}

enum SwipeToDismissState: Equatable {
    case block
    case allow
    case allowAfterConfirmation(title: String = L10n.Identification.ConfirmEnd.title,
                                body: String = L10n.Identification.ConfirmEnd.message,
                                confirm: String = L10n.Identification.ConfirmEnd.confirm,
                                deny: String = L10n.Identification.ConfirmEnd.deny)
}

enum IdentificationCoordinatorError: CustomNSError {
    case pinNilWhenTriedScan
    case noScreenToHandleEIDInteractionEvents
}

struct IdentificationCoordinator: ReducerProtocol {
    @Dependency(\.eIDInteractionManager) var eIDInteractionManager
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.storageManager) var storageManager
#if PREVIEW
    @Dependency(\.previewEIDInteractionManager) var previewEIDInteractionManager
#endif
    struct State: Equatable, IndexedRouterState, EIDInteractionHandler {
        var tokenURL: URL
        var pin: String?
        var attempt: Int = 0

        var swipeToDismiss: SwipeToDismissState {
            guard let lastScreen = states.last?.screen else { return .allow }
            return lastScreen.swipeToDismissState
        }
        
        var alert: AlertState<IdentificationCoordinator.Action>?
        
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        var states: [Route<IdentificationScreen.State>]
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> IdentificationCoordinator.Action? {
            for (index, state) in states.enumerated().reversed() {
                guard let action = state.screen.transformToLocalAction(event) else { continue }
                return .routeAction(index, action: action)
            }
            return nil
        }
    }
    
    enum Action: Equatable, IndexedRouterAction {
        case routeAction(Int, action: IdentificationScreen.Action)
        case updateRoutes([Route<IdentificationScreen.State>])
        case eIDInteractionEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case scanError(ScanError.State)
        case swipeToDismiss
        case afterConfirmEnd
        case dismissAlert
        case dismiss
        case back(tokenURL: URL)
#if PREVIEW
        case runDebugSequence(IdentifyDebugSequence)
#endif
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
#if PREVIEW
            case .runDebugSequence(let debugSequence):
                state.availableDebugActions = previewEIDInteractionManager.runIdentify(debugSequence: debugSequence)
                return .none
#endif
            case .routeAction(_, action: .scan(.wrongPIN(remainingAttempts: let remainingAttempts))):
                state.routes.presentSheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State(error: .incorrect,
                                                                                                         remainingAttempts: remainingAttempts)))
                return .none
            case .eIDInteractionEvent(let result):
                guard let localAction = state.transformToLocalAction(result) else {
                    issueTracker.capture(error: IdentificationCoordinatorError.noScreenToHandleEIDInteractionEvents)
                    logger.error("No screen found to handle EIDInteractionEvents")
                    return .none
                }
                return EffectTask(value: localAction)
            case .routeAction(_, action: .incorrectPersonalPIN(.done(let pin))):
                state.pin = pin
                state.attempt += 1
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .overview(.back)):
                return EffectTask.merge(
                    .cancel(id: CancelId.self),
                    EffectTask(value: .back(tokenURL: state.tokenURL))
                )
            case .routeAction(_, action: .overview(.loading(.identify))),
                 .routeAction(_, action: .scan(.restartAfterCancellation)),
                 .routeAction(_, action: .identificationCANCoordinator(.routeAction(_, action: .canScan(.restartAfterCancellation)))):
                let publisher: EIDInteractionPublisher
#if PREVIEW
                if previewEIDInteractionManager.isDebugModeEnabled {
                    let debuggableInteraction = previewEIDInteractionManager.debuggableIdentify(tokenURL: state.tokenURL)
                    state.availableDebugActions = debuggableInteraction.sequence
                    publisher = debuggableInteraction.publisher
                } else {
                    publisher = eIDInteractionManager.identify(tokenURL: state.tokenURL, messages: .identification)
                }
#else
                publisher = eIDInteractionManager.identify(tokenURL: state.tokenURL, messages: .identification)
#endif
                return publisher
                    .receive(on: mainQueue)
                    .catchToEffect(IdentificationCoordinator.Action.eIDInteractionEvent)
                    .cancellable(id: CancelId.self, cancelInFlight: true)
#if PREVIEW
            case .routeAction(_, action: .overview(.loading(.runDebugSequence(let sequence)))),
                 .routeAction(_, action: .scan(.runDebugSequence(let sequence))),
                 .routeAction(_, action: .identificationCANCoordinator(.routeAction(_, action: .canScan(.runDebugSequence(let sequence))))):
                return EffectTask(value: .runDebugSequence(sequence))
#endif
            case .routeAction(_, action: .overview(.loaded(.confirm(let identificationInformation)))):
                state.routes.push(.personalPIN(IdentificationPersonalPIN.State(identificationInformation: identificationInformation)))
                return .none
            case .routeAction(_, action: .personalPIN(.done(identificationInformation: let identificationInformation, pin: let pin))):
                state.pin = pin
                state.routes.push(
                    .scan(IdentificationPINScan.State(identificationInformation: identificationInformation,
                                                      pin: pin,
                                                      shared: SharedScan.State(startOnAppear: storageManager.identifiedOnce)))
                )
                return .none
            case .routeAction(_, action: .scan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
                return .none
            case .routeAction(_, action: .scan(.requestCAN(let identificationInformation))):
                let pinIsUnchecked = state.attempt == 0
                state.routes.push(.identificationCANCoordinator(.init(identificationInformation: identificationInformation,
                                                                      pin: pinIsUnchecked ? state.pin : nil,
                                                                      attempt: state.attempt,
                                                                      goToCanIntroScreen: pinIsUnchecked)))
                return .none
            case .routeAction(_, action: .scan(.shared(.showHelp))):
                state.routes.presentSheet(.error(ScanError.State(errorType: .help, retry: true)))
                return .none
            case .routeAction(_, action: .error(.retry)):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .error(.end)),
                 .routeAction(_, action: .incorrectPersonalPIN(.confirmEnd)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return EffectTask(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: mainQueue)
                    .eraseToEffect()
                
            case .routeAction(_, action: .overview(.end)):
                state.alert = AlertState.confirmEndInIdentification(.dismiss)
                return .none
            case .swipeToDismiss:
                switch state.swipeToDismiss {
                case .allow:
                    return .none
                case .block:
                    return .none
                case .allowAfterConfirmation(let title, let message, let confirm, let deny):
                    state.alert = AlertState(title: TextState(verbatim: title),
                                             message: TextState(verbatim: message),
                                             primaryButton: .destructive(TextState(verbatim: confirm),
                                                                         action: .send(.dismiss)),
                                             secondaryButton: .cancel(TextState(verbatim: deny)))
                    return .none
                }
            case .dismissAlert:
                state.alert = nil
                return .none
            default:
                return .none
            }
        }.forEachRoute {
            IdentificationScreen()
        }
    }
    
}

extension IdentificationCoordinator.State {
    var routes: [Route<IdentificationScreen.State>] {
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
                        if let pin {
                            state.pin = pin
                        }
                        
                        state.shared.attempt = attempt
#if PREVIEW
                        state.availableDebugActions = availableDebugActions
#endif
                        return .scan(state)
                    case .identificationCANCoordinator(var canStates):
                        canStates.states = canStates.states.map {
                            $0.map { canScreenState in
                                switch canScreenState {
                                case .canScan(var state):
#if PREVIEW
                                    state.availableDebugActions = availableDebugActions
#endif
                                    return IdentificationCANScreen.State.canScan(state)
                                default:
                                    return canScreenState
                                }
                            }
                        }
                        return .identificationCANCoordinator(canStates)
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

extension IdentificationCoordinator.State: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}

extension IdentificationCoordinator.State {
    init(tokenURL: URL, canGoBackToSetupIntro: Bool = false) {
        self.tokenURL = tokenURL
        states = [.root(.overview(.loading(IdentificationOverviewLoading.State(canGoBackToSetupIntro: canGoBackToSetupIntro))))]
    }
}

/*
 Happy path loading token until scanning:
 .identificationStarted
 .requestIdentificationRequestConfirmation
 .cardInteractionComplete
 .requestPIN(remainingAttempts: nil)
 .requestCardInsertion
 
 Happy path identification:
 .cardRecognized
 .identificationSuccessful
 .processCompletedSuccessfully
 
 Wrong pin identification:
 .cardRecognized
 .cardInteractionComplete
 .requestPIN(remainingAttempts: 3)
 .cardRemoved
 
 Card removed before process finished:
 .cardRecognized
 .identificationSuccessful (optional)
 .cardRemoved // difference from happy path?
 .processCompletedSuccessfully // not really successful
 
 Wrong card:
 .cardInteractionComplete
 .requestPIN(remainingAttempts: nil) // like cancel
 */

struct IdentificationCoordinatorView: View {
    let store: Store<IdentificationCoordinator.State, IdentificationCoordinator.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            TCARouter(store) { screen in
                SwitchStore(screen) {
                    CaseLet(state: /IdentificationScreen.State.overview,
                            action: IdentificationScreen.Action.overview,
                            then: IdentificationOverviewView.init)
                    CaseLet(state: /IdentificationScreen.State.personalPIN,
                            action: IdentificationScreen.Action.personalPIN,
                            then: IdentificationPersonalPINView.init)
                    CaseLet(state: /IdentificationScreen.State.incorrectPersonalPIN,
                            action: IdentificationScreen.Action.incorrectPersonalPIN,
                            then: IdentificationIncorrectPersonalPINView.init)
                    CaseLet(state: /IdentificationScreen.State.scan,
                            action: IdentificationScreen.Action.scan,
                            then: IdentificationPINScanView.init)
                    CaseLet(state: /IdentificationScreen.State.error,
                            action: IdentificationScreen.Action.error,
                            then: ScanErrorView.init)
                    CaseLet(state: /IdentificationScreen.State.identificationCANCoordinator,
                            action: IdentificationScreen.Action.identificationCANCoordinator,
                            then: IdentificationCANCoordinatorView.init)
                }
            }
            .alert(store.scope(state: \.alert), dismiss: IdentificationCoordinator.Action.dismissAlert)
            .navigationBarHidden(false)
            .interactiveDismissDisabled(viewStore.swipeToDismiss != .allow) {
                viewStore.send(IdentificationCoordinator.Action.swipeToDismiss)
            }
        }
    }
}
