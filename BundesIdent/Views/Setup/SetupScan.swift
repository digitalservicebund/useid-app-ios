import SwiftUI
import ComposableArchitecture
import Combine
import Sentry
import Analytics
import OSLog

struct SetupScan: ReducerProtocol {
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.logger) var logger
    @Dependency(\.storageManager) var storageManager
    @Dependency(\.uuid) var uuid
    @Dependency(\.idInteractionManager) var idInteractionManager
    
    struct State: Equatable, IDInteractionHandler {
        var transportPIN: String
        var newPIN: String
        var shared: SharedScan.State = .init(forceDismissButtonTitle: L10n.FirstTimeUser.Scan.forceDismiss)
        var remainingAttempts: Int?
        var alert: AlertState<SetupScan.Action>?
        var isScanInitiated = false
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
        case requestCANAndChangedPIN(pin: String)
        case wrongTransportPIN
        case error(ScanError.State)
        case cancelScan
        case scannedSuccessfully
        case dismissAlert
#if PREVIEW
        case runDebugSequence(ChangePINDebugSequence)
#endif
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
#if PREVIEW
        case .runDebugSequence:
            return .none
#endif
        case .onAppear:
            return .none
        case .shared(.startScan):
            state.shared.startOnAppear = true
            state.shared.cardRecognized = false
            state.shared.preventSecondScanningAttempt = true
            if state.isScanInitiated {
                idInteractionManager.setPIN(state.transportPIN)
                return .none
            } else {
                return EffectTask(value: .shared(.initiateScan))
            }
        case .shared(.initiateScan):
            state.isScanInitiated = true
            return .none
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
        case .scanEvent(.success(let event)):
            return handle(state: &state, event: event)
        case .cancelScan:
            if state.shared.cardRecognized {
                issueTracker.capture(error: SetupScanError.cancelAfterCardRecognized)
            }
            return .cancel(id: CancelId.self)
        case .error:
            return .cancel(id: CancelId.self)
        case .wrongTransportPIN:
            return .none
        case .scannedSuccessfully:
            storageManager.setupCompleted = true
            return .none
        case .shared(.showHelp), .shared(.forceDismiss):
            return .none
        case .requestCANAndChangedPIN:
            return .none
        case .dismissAlert:
            state.alert = nil
            return .none
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<SetupScan.Action> {
        switch event {
        case .authenticationStarted:
            logger.info("Authentication started.")
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
        case .pinChangeStarted:
            logger.info("PIN change started.")
        case .newPINRequested:
            logger.info("Providing new PIN.")
            idInteractionManager.setNewPIN(state.newPIN)
            return .none
        case .canRequested:
            logger.info("CAN requested.")
            state.shared.scanAvailable = true
            idInteractionManager.interrupt()
            return EffectTask(value: .requestCANAndChangedPIN(pin: state.newPIN))
                .delay(for: 2, scheduler: mainQueue) // this delay is here to fix a bug where this particular screen was presented incorrectly
                .eraseToEffect()
        case .pukRequested:
            logger.info("PUK requested, so card is blocked. Callback not implemented yet.")
            idInteractionManager.interrupt()
            return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
        case .pinRequested(remainingAttempts: let newRemainingAttempts):
            logger.info("Providing PIN with \(String(describing: newRemainingAttempts)) remaining attempts.")
            let remainingAttemptsBefore = state.remainingAttempts
            state.remainingAttempts = newRemainingAttempts

            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = newRemainingAttempts else {
                return EffectTask(value: .cancelScan)
            }

            // Wrong transport/personal PIN provided
            if let remainingAttemptsBefore,
               remainingAttempts < remainingAttemptsBefore {
                idInteractionManager.interrupt()
                return EffectTask(value: .wrongTransportPIN)
            }
            idInteractionManager.setPIN(state.transportPIN)
            return .none
        case .authenticationSucceeded, .authenticationRequestConfirmationRequested, .certificateDescriptionRetrieved:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

enum SetupScanError: Error, Equatable, CustomNSError {
    case eIDInteraction(EIDInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
    case cancelAfterCardRecognized
}

struct SetupScanView: View {
    
    var store: Store<SetupScan.State, SetupScan.Action>
    
    init(store: Store<SetupScan.State, SetupScan.Action>) {
        self.store = store
    }
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: SetupScan.Action.shared))
            .interactiveDismissDisabled()
            .onAppear {
                ViewStore(store).send(.onAppear)
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: SetupScan.Action.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}
