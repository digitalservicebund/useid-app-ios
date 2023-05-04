import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import Analytics

enum SetupCoordinatorError: CustomNSError {
    case noScreenToHandleEIDInteractionEvents
}

struct SetupCoordinator: ReducerProtocol {
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.eIDInteractionManager) var eIDInteractionManager
    @Dependency(\.analytics) var analytics
#if PREVIEW
    @Dependency(\.previewEIDInteractionManager) var previewEIDInteractionManager
#endif
    
    struct State: Equatable, IndexedRouterState, EIDInteractionHandler {
        var transportPIN: String
        var attempt: Int
        var tokenURL: URL?
        var alert: AlertState<Action>?
        
#if PREVIEW
        var availableDebugActions: [ChangePINDebugSequence] = []
#endif
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            for (index, state) in states.enumerated().reversed() {
                guard let action = state.screen.transformToLocalAction(event) else { continue }
                return .routeAction(index, action: action)
            }
            return nil
        }
        
        var routes: [Route<SetupScreen.State>] {
            get {
                states.map {
                    $0.map { setupScreenState in
                        switch setupScreenState {
                        case .scan(var scanState):
                            scanState.transportPIN = transportPIN
                            scanState.shared.attempt = attempt
                            
#if PREVIEW
                            scanState.availableDebugActions = availableDebugActions
#endif
                            
                            return .scan(scanState)
                        case .intro(var state):
                            state.tokenURL = tokenURL
                            return .intro(state)

                        case .introVariation(var state):
                            state.tokenURL = tokenURL
                            return .introVariation(state)

                        case .setupCANCoordinator(var canStates):
                            canStates.states = canStates.states.map {
                                $0.map { canScreenState in
                                    switch canScreenState {
                                    case .canScan(var state):
#if PREVIEW
                                        state.availableDebugActions = availableDebugActions
#endif
                                        return SetupCANScreen.State.canScan(state)
                                    default:
                                        return canScreenState
                                    }
                                }
                            }
                            return .setupCANCoordinator(canStates)
                            
                        default:
                            return setupScreenState
                        }
                    }
                }
            }
            set {
                states = newValue
            }
        }
        
        var states: [Route<SetupScreen.State>]
        
        init(transportPIN: String = "", attempt: Int = 0, tokenURL: URL? = nil, alert: AlertState<SetupCoordinator.Action>? = nil, states: [Route<SetupScreen.State>]? = nil) {
            self.transportPIN = transportPIN
            self.attempt = attempt
            self.tokenURL = tokenURL
            self.alert = alert
            self.states = states ?? [.root(.intro(.init(tokenURL: tokenURL)))]
        }
    }
    
    indirect enum Action: Equatable, IndexedRouterAction {
        case routeAction(Int, action: SetupScreen.Action)
        case updateRoutes([Route<SetupScreen.State>])
        case eIDInteractionEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case end
        case confirmEnd
        case afterConfirmEnd
        case dismissAlert
        case dismiss
#if PREVIEW
        case runDebugSequence(ChangePINDebugSequence)
#endif
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
#if PREVIEW
            case .runDebugSequence(let debugSequence):
                state.availableDebugActions = previewEIDInteractionManager.runChangePIN(debugSequence: debugSequence)
                return .none
            case .routeAction(_, action: .scan(.runDebugSequence(let sequence))),
                 .routeAction(_, action: .setupCANCoordinator(.routeAction(_, action: .canScan(.runDebugSequence(let sequence))))):
                return EffectTask(value: .runDebugSequence(sequence))
#endif
            case .eIDInteractionEvent(let result):
                guard let localAction = state.transformToLocalAction(result) else {
                    issueTracker.capture(error: SetupCoordinatorError.noScreenToHandleEIDInteractionEvents)
                    logger.error("No screen found to handle EIDInteractionEvents")
                    return .none
                }
                return EffectTask(value: localAction)
            case .routeAction(_, .intro(.chooseStartSetup)):
                state.routes.push(.transportPINIntro)
                return .trackEvent(category: "firstTimeUser", action: "buttonPressed", name: "startSetup", analytics: analytics)
            case .routeAction(_, .intro(.chooseSkipSetup(tokenURL: nil))):
                state.routes.push(.alreadySetupConfirmation)
                return .trackEvent(category: "firstTimeUser", action: "buttonPressed", name: "alreadySetup", analytics: analytics)
            case .routeAction(_, .transportPINIntro(.choosePINLetterAvailable)):
                state.routes.push(.transportPIN(SetupTransportPIN.State()))
            case .routeAction(_, .transportPINIntro(.choosePINLetterMissing)):
                state.routes.push(.missingPINLetter(MissingPINLetter.State()))
            case .routeAction(_, .transportPIN(.done(let transportPIN))):
                state.transportPIN = transportPIN
                state.routes.push(.personalPINIntro)
            case .routeAction(_, .personalPINIntro(.continue)):
                state.routes.push(.personalPINInput(SetupPersonalPINInput.State()))
            case .routeAction(_, action: .personalPINInput(.done(pin: let pin))):
                state.routes.push(.personalPINConfirm(SetupPersonalPINConfirm.State(enteredPIN1: pin)))
            case .routeAction(_, action: .personalPINConfirm(.confirmMismatch)):
                state.routes.pop()
            case .routeAction(_, action: .personalPINConfirm(.done(pin: let pin))):
                state.routes.pop()
                state.routes.push(.scan(SetupScan.State(transportPIN: state.transportPIN, newPIN: pin)))
            case .routeAction(_, action: .scan(.shared(.initiateScan))),
                 .routeAction(_, action: .setupCANCoordinator(.routeAction(_, action: .canScan(.restartAfterCancellation)))):
                let publisher: EIDInteractionPublisher
                 #if PREVIEW
                if previewEIDInteractionManager.isDebugModeEnabled {
                    let debuggableInteraction = previewEIDInteractionManager.debuggableChangePIN()
                    state.availableDebugActions = debuggableInteraction.sequence
                    publisher = debuggableInteraction.publisher
                } else {
                    publisher = eIDInteractionManager.changePIN(messages: .setup)
                }
                 #else
                publisher = eIDInteractionManager.changePIN(messages: .setup)
                 #endif
                return publisher
                    .receive(on: mainQueue)
                    .catchToEffect(Action.eIDInteractionEvent)
                    .cancellable(id: CancelId.self, cancelInFlight: true)
            case .routeAction(_, action: .scan(.scannedSuccessfully)):
                state.routes.push(.done(SetupDone.State(tokenURL: state.tokenURL)))
            case .routeAction(_, action: .scan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
            case .routeAction(_, action: .scan(.requestCANAndChangedPIN(pin: let pin))):
                let transportPINIsUnchecked = state.attempt == 0
                state.routes.push(.setupCANCoordinator(SetupCANCoordinator.State(oldTransportPIN: state.transportPIN,
                                                                                 transportPIN: transportPINIsUnchecked ? state.transportPIN : nil,
                                                                                 pin: pin,
                                                                                 tokenURL: state.tokenURL,
                                                                                 attempt: state.attempt,
                                                                                 goToCanIntroScreen: transportPINIsUnchecked)))
                return .none
            case .routeAction(_, action: .scan(.shared(.showHelp))):
                state.routes.presentSheet(.error(ScanError.State(errorType: .help, retry: true)))
            case .routeAction(_, action: .error(.retry)):
                state.routes.dismiss()
            case .routeAction(_, action: .error(.end)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return EffectTask(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: mainQueue)
                    .eraseToEffect()
            case .routeAction(_, action: .scan(.wrongTransportPIN)):
                state.routes.presentSheet(.incorrectTransportPIN(SetupIncorrectTransportPIN.State()))
            case .routeAction(_, action: .incorrectTransportPIN(.confirmEnd)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return EffectTask(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: mainQueue)
                    .eraseToEffect()
            case .routeAction(_, action: .incorrectTransportPIN(.done(let transportPIN))):
                state.transportPIN = transportPIN
                state.attempt += 1
                state.routes.dismiss()
            case .end:
                state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                                         message: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                                         primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm),
                                                                     action: .send(.confirmEnd)),
                                         secondaryButton: .cancel(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
            case .confirmEnd:
                return .none
            case .dismissAlert:
                state.alert = nil
                return .none
            case .dismiss:
                state.routes.dismissAll()
                return .none
            default:
                break
            }
            return .none
        }.forEachRoute {
            SetupScreen()
        }
    }
}

struct SetupCoordinatorView: View {
    let store: Store<SetupCoordinator.State, SetupCoordinator.Action>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /SetupScreen.State.intro,
                        action: SetupScreen.Action.intro,
                        then: SetupIntroView.init)
                CaseLet(state: /SetupScreen.State.transportPINIntro,
                        action: SetupScreen.Action.transportPINIntro,
                        then: SetupTransportPINIntroView.init)
                CaseLet(state: /SetupScreen.State.transportPIN,
                        action: SetupScreen.Action.transportPIN,
                        then: SetupTransportPINView.init)
                CaseLet(state: /SetupScreen.State.personalPINIntro,
                        action: SetupScreen.Action.personalPINIntro,
                        then: SetupPersonalPINIntroView.init)
                CaseLet(state: /SetupScreen.State.personalPINInput,
                        action: SetupScreen.Action.personalPINInput,
                        then: SetupPersonalPINInputView.init)
                CaseLet(state: /SetupScreen.State.scan,
                        action: SetupScreen.Action.scan,
                        then: SetupScanView.init)
                CaseLet(state: /SetupScreen.State.done,
                        action: SetupScreen.Action.done,
                        then: SetupDoneView.init)
                CaseLet(state: /SetupScreen.State.error,
                        action: SetupScreen.Action.error,
                        then: ScanErrorView.init)
                CaseLet(state: /SetupScreen.State.incorrectTransportPIN,
                        action: SetupScreen.Action.incorrectTransportPIN,
                        then: SetupIncorrectTransportPINView.init)
                Default {
                    // There is a maximum case let statements allowed per switch store view.
                    // This works around this issue by nesting a second switch store inside the default case.
                    // For more information see: https://github.com/pointfreeco/swift-composable-architecture/issues/602
                    SwitchStore(screen) {
                        CaseLet(state: /SetupScreen.State.introVariation,
                                action: SetupScreen.Action.intro,
                                then: SetupIntroVariationView.init)
                        CaseLet(state: /SetupScreen.State.alreadySetupConfirmation,
                                action: SetupScreen.Action.alreadySetupConfirmation,
                                then: AlreadySetupConfirmationView.init)
                        CaseLet(state: /SetupScreen.State.missingPINLetter,
                                action: SetupScreen.Action.missingPINLetter,
                                then: MissingPINLetterView.init)
                        CaseLet(state: /SetupScreen.State.personalPINConfirm,
                                action: SetupScreen.Action.personalPINConfirm,
                                then: SetupPersonalPINConfirmView.init)
                        CaseLet(state: /SetupScreen.State.setupCANCoordinator,
                                action: SetupScreen.Action.setupCANCoordinator,
                                then: SetupCANCoordinatorView.init)
                    }
                }
            }
        }
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
        .navigationBarHidden(false)
    }
}

extension SetupCoordinator.State: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}
