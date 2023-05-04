import SwiftUI
import ComposableArchitecture
import Combine
import Sentry
import OSLog

struct SetupScan: ReducerProtocol {
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.logger) var logger
    @Dependency(\.storageManager) var storageManager
    @Dependency(\.eIDInteractionManager) var eIDInteractionManager
    @Dependency(\.analytics) var analytics

    struct State: Equatable, EIDInteractionHandler {
        var transportPIN: String
        var newPIN: String
        var shared: SharedScan.State = .init()
        var lastRemainingAttempts: Int?
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
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case requestCANAndChangedPIN(pin: String)
        case wrongTransportPIN
        case error(ScanError.State)
        case scannedSuccessfully
        case dismissAlert
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
    #if PREVIEW
            case .runDebugSequence:
                return .none
    #endif
            case .shared(.startScan(let userInitiated)):
                var trackingEvent = EffectTask<Action>.none
                if userInitiated {
                    trackingEvent = .trackEvent(category: "firstTimeUser",
                                                action: "buttonPressed",
                                                name: "scan",
                                                analytics: analytics)
                }
                if state.isScanInitiated {
                    eIDInteractionManager.setPIN(state.transportPIN)
                    return trackingEvent
                } else {
                    return .concatenate(EffectTask(value: .shared(.initiateScan)), trackingEvent)
                }
            case .shared(.initiateScan):
                state.isScanInitiated = true
                return .none
            case .shared:
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
            case .error:
                return .cancel(id: CancelId.self)
            case .wrongTransportPIN:
                return .none
            case .scannedSuccessfully:
                storageManager.setupCompleted = true
                return .none
            case .requestCANAndChangedPIN:
                return .none
            case .dismissAlert:
                state.alert = nil
                return .none
            }
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<SetupScan.Action> {
        switch event {
        case .identificationStarted:
            logger.info("Identification started.")
        case .cardInsertionRequested:
            logger.info("Card insertion requested.")
        case .cardRecognized:
            logger.info("Card recognized.")
        case .pinChangeSucceeded:
            return EffectTask(value: .scannedSuccessfully)
        case .pinChangeStarted:
            logger.info("PIN change started.")
        case .pinChangeCancelled:
            state.isScanInitiated = false
            return .cancel(id: CancelId.self)
        case .newPINRequested:
            logger.info("Providing new PIN.")
            eIDInteractionManager.setNewPIN(state.newPIN)
            return .none
        case .canRequested:
            logger.info("CAN requested.")
            state.shared.scanAvailable = true
            eIDInteractionManager.interrupt()
            return EffectTask(value: .requestCANAndChangedPIN(pin: state.newPIN))
                .delay(for: 2, scheduler: mainQueue) // this delay is here to fix a bug where this particular screen was presented incorrectly
                .eraseToEffect()
        case .pukRequested:
            logger.info("PUK requested, so card is blocked. Callback not implemented yet.")
            eIDInteractionManager.interrupt()
            state.shared.scanAvailable = false
            return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
        case .pinRequested(remainingAttempts: let remainingAttempts):
            logger.info("Providing PIN with \(String(describing: remainingAttempts)) remaining attempts.")

            let lastRemainingAttempts = state.lastRemainingAttempts
            state.lastRemainingAttempts = remainingAttempts

            if let remainingAttempts,
               let lastRemainingAttempts,
               remainingAttempts < lastRemainingAttempts {
                eIDInteractionManager.interrupt()
                return EffectTask(value: .wrongTransportPIN)
            } else {
                eIDInteractionManager.setPIN(state.transportPIN)
                return .none
            }
        case .identificationSucceeded,
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

enum SetupScanError: Error, Equatable, CustomNSError {
    case eIDInteraction(EIDInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct SetupScanView: View {
    
    var store: Store<SetupScan.State, SetupScan.Action>
    
    init(store: Store<SetupScan.State, SetupScan.Action>) {
        self.store = store
    }
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: SetupScan.Action.shared))
            .interactiveDismissDisabled()
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: SetupScan.Action.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}
