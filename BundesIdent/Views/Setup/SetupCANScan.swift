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
        var shared: SharedScan.State = .init(forceDismissButtonTitle: L10n.FirstTimeUser.Scan.forceDismiss)
        
        var alert: AlertState<SetupCANScan.Action>?
#if PREVIEW
        var availableDebugActions: [ChangePINDebugSequence] = []
#endif
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            .scanEvent(event)
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case wrongPIN(remainingAttempts: Int)
        case incorrectCAN
        case scannedSuccessfully
        case error(ScanError.State)
        case cancelSetup
        case dismiss
        case dismissAlert
#if PREVIEW
        case runDebugSequence(ChangePINDebugSequence)
#endif
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return state.shared.startOnAppear ? EffectTask(value: .shared(.startScan)) : .none
        case .shared(.startScan):
            eIDInteractionManager.setCAN(state.can)
            state.shared.preventSecondScanningAttempt = true
            return .trackEvent(category: "Setup",
                               action: "buttonPressed",
                               name: "canScan",
                               analytics: analytics)
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
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<SetupCANScan.Action> {
        switch event {
        case .identificationStarted:
            logger.info("Identification started.")
        case .pinChangeStarted:
            logger.info("PIN Change started.")
        case .cardInsertionRequested:
            logger.info("Card insertion requested.")
            state.shared.cardRecognized = false
        case .cardRecognized:
            logger.info("Card recognized.")
            state.shared.cardRecognized = true
        case .cardRemoved:
            logger.info("Card removed.")
        case .pinChangeSucceeded:
            return EffectTask(value: .scannedSuccessfully)
        case .canRequested:
            logger.info("Wrong CAN provided")
            eIDInteractionManager.interrupt()
            return EffectTask(value: .incorrectCAN)
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
        case .identificationSucceeded,
             .identificationRequestConfirmationRequested,
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
            .onAppear {
                ViewStore(store).send(.onAppear)
            }
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
