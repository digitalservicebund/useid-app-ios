import SwiftUI
import ComposableArchitecture
import Combine
import Sentry

struct SetupCANScan: ReducerProtocol {
    
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.storageManager) var storageManager
    @Dependency(\.logger) var logger
    @Dependency(\.eIDInteractionManager) var eIDInteractionManager
    
    struct State: Equatable, EIDInteractionHandler {
        var transportPIN: String
        var newPIN: String
        var can: String
        var shared: SharedScan.State = .init()
        var shouldRestartAfterCancellation = false

        var alert: AlertState<SetupCANScan.Action>?
#if PREVIEW
        var availableDebugActions: [ChangePINDebugSequence] = []
#endif
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            .scanEvent(event)
        }
    }
    
    enum Action: Equatable {
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case wrongPIN(remainingAttempts: Int)
        case incorrectCAN
        case scannedSuccessfully
        case error(ScanError.State)
        case cancelSetup
        case dismiss
        case dismissAlert
        case changePIN
#if PREVIEW
        case runDebugSequence(ChangePINDebugSequence)
#endif
    }

    var body: some ReducerProtocol<State, Action> {
        Scope(state: \.shared, action: /Action.shared) {
            SharedScan()
        }
        Reduce { state, action in
            switch action {
            case .shared(.startScan(let userInitiated)):
                state.shared.scanAvailable = false
                var trackingEvent = EffectTask<Action>.none
                if userInitiated {
                    trackingEvent = .trackEvent(category: "Setup",
                                                action: "buttonPressed",
                                                name: "canScan",
                                                analytics: analytics)
                }
                if state.shouldRestartAfterCancellation {
                    return .concatenate(EffectTask(value: .changePIN), trackingEvent)
                } else {
                    eIDInteractionManager.setCAN(state.can)
                    return trackingEvent
                }
            case .scanEvent(.success(let event)):
                return handle(state: &state, event: event)
            case .scanEvent(.failure(let error)):
                RedactedEIDInteractionError(error).flatMap(issueTracker.capture(error:))

                switch error {
                case .cardDeactivated:
                    state.shared.scanAvailable = false
                    return EffectTask(value: .error(ScanError.State(errorType: .cardDeactivated, retry: state.shared.scanAvailable)))
                default:
                    state.shared.scanAvailable = true
                    return EffectTask(value: .error(ScanError.State(errorType: .eIDInteraction(error), retry: state.shared.scanAvailable)))
                }
            case .wrongPIN:
                return .none
            case .scannedSuccessfully:
                storageManager.setupCompleted = true
                return .none
            case .cancelSetup:
                state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                                         message: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                                         primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm),
                                                                     action: .send(.dismiss)),
                                         secondaryButton: .cancel(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
                return .none
            case .dismissAlert:
                state.alert = nil
                return .none
            default:
                return .none
            }
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<SetupCANScan.Action> {
        switch event {
        case .pinChangeStarted:
            logger.info("PIN Change started.")
            state.shared.scanAvailable = false
        case .cardInsertionRequested:
            logger.info("Card insertion requested.")
        case .cardRecognized:
            logger.info("Card recognized.")
        case .pinChangeSucceeded:
            return EffectTask(value: .scannedSuccessfully)
        case .pinChangeCancelled:
            state.shouldRestartAfterCancellation = true
            state.shared.scanAvailable = true
            return .none
        case .canRequested:
            if state.shouldRestartAfterCancellation {
                state.shouldRestartAfterCancellation = false
                eIDInteractionManager.setCAN(state.can)
                return .none
            } else {
                logger.info("Wrong CAN provided")
                eIDInteractionManager.interrupt()
                return EffectTask(value: .incorrectCAN)
            }
        case .pinRequested:
            eIDInteractionManager.setPIN(state.transportPIN)
            return .none
        case .pukRequested:
            logger.info("PUK requested, so card is blocked. Callback not implemented yet.")
            eIDInteractionManager.interrupt()
            state.shared.scanAvailable = false
            return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
            
        case .newPINRequested:
            eIDInteractionManager.setNewPIN(state.newPIN)
            return .none
        case .identificationStarted,
             .identificationSucceeded,
             .identificationRequestConfirmationRequested,
             .identificationCancelled,
             .certificateDescriptionRetrieved:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct SetupCANScanView: View {
    
    var store: Store<SetupCANScan.State, SetupCANScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: SetupCANScan.Action.shared))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        ViewStore(store).send(.cancelSetup)
                    }
                    .bodyLRegular(color: .accentColor)
                }
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: SetupCANScan.Action.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

#if DEBUG

struct SetupCANScan_Previews: PreviewProvider {
    static var previews: some View {
        SetupCANScanView(store: Store(initialState: SetupCANScan.State(transportPIN: "12345",
                                                                       newPIN: "123456",
                                                                       can: "123456"),
                                      reducer: SetupCANScan()))
    }
}

#endif
