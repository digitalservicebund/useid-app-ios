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
    
    struct State: Equatable, IDInteractionHandler {
        var transportPIN: String
        var newPIN: String
        var shared: SharedScan.State = .init()
        var remainingAttempts: Int?
        var alert: AlertState<SetupScan.Action>?
#if PREVIEW
        var availableDebugActions: [ChangePINDebugSequence] = []
#endif
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> Action? {
            .scanEvent(event)
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
        case requestCANAndChangedPIN(pin: String, callback: CANAndChangedPINCallback)
        case wrongTransportPIN(remainingAttempts: Int)
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
            state.shared.showInstructions = false
            state.shared.cardRecognized = false
            guard !state.shared.isScanning else { return .none }
            state.shared.isScanning = true
            return EffectTask(value: .shared(.initiateScan))
        case .shared(.initiateScan):
            return .none
        case .scanEvent(.failure(let error)):
            RedactedIDCardInteractionError(error).flatMap(issueTracker.capture(error:))
            state.shared.isScanning = false
                
            switch error {
            case .cardDeactivated:
                state.shared.scanAvailable = false
                return EffectTask(value: .error(ScanError.State(errorType: .cardDeactivated, retry: state.shared.scanAvailable)))
            case .cardBlocked:
                state.shared.scanAvailable = false
                return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: state.shared.scanAvailable)))
            default:
                state.shared.scanAvailable = true
                return EffectTask(value: .error(ScanError.State(errorType: .idCardInteraction(error), retry: state.shared.scanAvailable)))
            }
        case .scanEvent(.success(let event)):
            return handle(state: &state, event: event)
        case .cancelScan:
            state.shared.isScanning = false
            if state.shared.cardRecognized {
                issueTracker.capture(error: SetupScanError.cancelAfterCardRecognized)
            }
            return .cancel(id: CancelId.self)
        case .error:
            state.shared.isScanning = false
            return .cancel(id: CancelId.self)
        case .wrongTransportPIN:
            state.shared.isScanning = false
            return .cancel(id: CancelId.self)
        case .scannedSuccessfully:
            storageManager.setupCompleted = true
            return .cancel(id: CancelId.self)
        case .shared(.showNFCInfo):
            state.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                     message: TextState(L10n.HelpNFC.body),
                                     dismissButton: .cancel(TextState(L10n.General.ok),
                                                            action: .send(.dismissAlert)))
            return .trackEvent(category: "firstTimeUser",
                               action: "alertShown",
                               name: "NFCInfo",
                               analytics: analytics)
        case .shared(.showHelp):
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
            state.shared.isScanning = true
        case .cardInteractionComplete:
            logger.info("Card interaction complete.")
        case .requestCardInsertion:
            logger.info("Request Card insertion.")
            state.shared.showProgressCaption = nil
            state.shared.isScanning = true
            state.shared.cardRecognized = false
        case .cardRecognized:
            logger.info("Card recognized.")
            state.shared.isScanning = true
            state.shared.cardRecognized = true
        case .cardRemoved:
            state.shared.showProgressCaption = ProgressCaption(title: L10n.FirstTimeUser.Scan.Progress.title,
                                                               body: L10n.FirstTimeUser.Scan.Progress.body)
            logger.info("Card removed.")
        case .processCompletedSuccessfullyWithoutRedirect:
            return EffectTask(value: .scannedSuccessfully)
        case .pinManagementStarted:
            logger.info("PIN Management started.")
        case .requestChangedPIN(let newRemainingAttempts, let pinCallback):
            logger.info("Providing changed PIN with \(String(describing: newRemainingAttempts)) remaining attempts.")
            let remainingAttemptsBefore = state.remainingAttempts
            state.remainingAttempts = newRemainingAttempts
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = newRemainingAttempts else {
                return EffectTask(value: .cancelScan)
            }
            
            // Wrong transport/personal PIN provided
            if let remainingAttemptsBefore,
               remainingAttempts < remainingAttemptsBefore {
                return EffectTask(value: .wrongTransportPIN(remainingAttempts: remainingAttempts))
            }
            
            pinCallback(state.transportPIN, state.newPIN)
        case .requestCANAndChangedPIN(let callback):
            let callbackId = uuid.callAsFunction()
            let canAndChangedPINCallback = CANAndChangedPINCallback(id: callbackId, callback: { payload in
                callback(payload.oldPIN, payload.can, payload.newPIN)
            })
            logger.info("PIN and CAN request: \(callbackId)")
            state.shared.isScanning = false
            state.shared.scanAvailable = true
            return EffectTask(value: .requestCANAndChangedPIN(pin: state.newPIN, callback: canAndChangedPINCallback))
                .delay(for: 2, scheduler: mainQueue) // this delay is here to fix a bug where this particular screen was presented incorrectly
                .eraseToEffect()
        case .requestPUK:
            logger.info("PUK requested, so card is blocked. Callback not implemented yet.")
            return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
        case .requestPIN(remainingAttempts: _, pinCallback: let pinCallback):
            pinCallback(state.transportPIN)
            return .none
        case .requestCAN,
             .requestPINAndCAN,
             .processCompletedSuccessfullyWithRedirect,
             .requestAuthenticationRequestConfirmation,
             .authenticationSuccessful:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

enum SetupScanError: Error, Equatable, CustomNSError {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
    case cancelAfterCardRecognized
}

struct SetupScanView: View {
    
    var store: Store<SetupScan.State, SetupScan.Action>
    
    init(store: Store<SetupScan.State, SetupScan.Action>) {
        self.store = store
    }
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: SetupScan.Action.shared),
                       instructionsTitle: L10n.FirstTimeUser.ScanInstructions.title,
                       instructionsBody: L10n.FirstTimeUser.ScanInstructions.body,
                       instructionsScanButtonTitle: L10n.FirstTimeUser.Scan.scan,
                       scanTitle: L10n.FirstTimeUser.Scan.Title.ios,
                       scanBody: L10n.FirstTimeUser.Scan.Body.ios,
                       scanButton: L10n.FirstTimeUser.Scan.scan)
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
