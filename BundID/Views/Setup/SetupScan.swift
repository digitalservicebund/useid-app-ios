import SwiftUI
import ComposableArchitecture
import Combine
import Sentry

enum SetupScanError: Error, Equatable {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct SetupScanState: Equatable {
    var transportPIN: String
    var newPIN: String
    var shared: SharedScanState = SharedScanState()
    var remainingAttempts: Int?
    var alert: AlertState<SetupScanAction>?
#if PREVIEW
    var availableDebugActions: [ChangePINDebugSequence] = []
#endif
}

enum SetupScanAction: Equatable {
    case onAppear
    case shared(SharedScanAction)
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case wrongTransportPIN(remainingAttempts: Int)
    case error(ScanErrorState)
    case cancelScan
    case scannedSuccessfully
    case dismissAlert
#if PREVIEW
    case runDebugSequence(ChangePINDebugSequence)
#endif
}

let setupScanReducer = Reducer<SetupScanState, SetupScanAction, AppEnvironment> { state, action, environment in
    
    enum CancelId {}
    
    switch action {
#if PREVIEW
    case .runDebugSequence(let debugSequence):
        state.availableDebugActions = environment.debugIDInteractionManager.runChangePIN(debugSequence: debugSequence)
        return .none
#endif
    case .onAppear:
        return .none
    case .shared(.startScan):
        state.shared.showInstructions = false
        
        guard !state.shared.isScanning else { return .none }
        state.shared.isScanning = true
        
        let publisher: EIDInteractionPublisher
#if PREVIEW
        if MOCK_OPENECARD {
            let debuggableInteraction = environment.debugIDInteractionManager.debuggableChangePIN()
            state.availableDebugActions = debuggableInteraction.sequence
            publisher = debuggableInteraction.publisher
        } else {
            publisher = environment.idInteractionManager.changePIN(nfcMessagesProvider: SetupNFCMessageProvider())
        }
#else
        publisher = environment.idInteractionManager.changePIN(nfcMessagesProvider: SetupNFCMessageProvider())
#endif
        return .concatenate(
            .trackEvent(category: "firstTimeUser",
                        action: "buttonPressed",
                        name: "scan",
                        analytics: environment.analytics),
            publisher
                .receive(on: environment.mainQueue)
                .catchToEffect(SetupScanAction.scanEvent)
                .cancellable(id: CancelId.self, cancelInFlight: true)
        )
    case .scanEvent(.failure(let error)):
        RedactedIDCardInteractionError(error).flatMap(environment.issueTracker.capture(error:))
        state.shared.isScanning = false
        
        switch error {
        case .cardDeactivated:
            state.shared.scanAvailable = false
            return Effect(value: .error(ScanErrorState(errorType: .cardDeactivated, retry: state.shared.scanAvailable)))
        case .cardBlocked:
            state.shared.scanAvailable = false
            return Effect(value: .error(ScanErrorState(errorType: .cardBlocked, retry: state.shared.scanAvailable)))
        default:
            state.shared.scanAvailable = true
            return Effect(value: .error(ScanErrorState(errorType: .idCardInteraction(error), retry: state.shared.scanAvailable)))
        }
    case .scanEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .cancelScan:
        state.shared.isScanning = false
        return .cancel(id: CancelId.self)
    case .error:
        state.shared.isScanning = false
        return .cancel(id: CancelId.self)
    case .wrongTransportPIN:
        state.shared.isScanning = false
        return .cancel(id: CancelId.self)
    case .scannedSuccessfully:
        environment.storageManager.updateSetupCompleted(true)
        return .cancel(id: CancelId.self)
    case .shared(.showNFCInfo):
        state.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                 message: TextState(L10n.HelpNFC.body),
                                 dismissButton: .cancel(TextState(L10n.General.ok),
                                                        action: .send(.dismissAlert)))
        return .trackEvent(category: "firstTimeUser",
                           action: "alertShown",
                           name: "NFCInfo",
                           analytics: environment.analytics)
    case .shared(.showHelp):
        return .none
    case .dismissAlert:
        state.alert = nil
        return .none
    }
}

extension SetupScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<SetupScanAction, Never> {
        switch event {
        case .authenticationStarted:
            print("Authentication started")
            shared.isScanning = true
        case .requestCardInsertion:
            shared.showProgressCaption = nil
            shared.isScanning = true
        case .cardInteractionComplete:
            print("Card interaction complete.")
        case .cardRecognized:
            print("Card recognized.")
            shared.isScanning = true
        case .cardRemoved:
            shared.showProgressCaption = ProgressCaption(title: L10n.FirstTimeUser.Scan.Progress.title,
                                                         body: L10n.FirstTimeUser.Scan.Progress.body)
            print("Card removed.")
        case .processCompletedSuccessfullyWithoutRedirect:
            return Effect(value: .scannedSuccessfully)
        case .pinManagementStarted: print("PIN Management started.")
        case .requestChangedPIN(let newRemainingAttempts, let pinCallback):
            print("Providing changed PIN with \(String(describing: newRemainingAttempts)) remaining attempts.")
            let remainingAttemptsBefore = remainingAttempts
            remainingAttempts = newRemainingAttempts
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = newRemainingAttempts else {
                return Effect(value: .cancelScan)
            }
            
            // Wrong transport/personal PIN provided
            if let remainingAttemptsBefore = remainingAttemptsBefore,
               remainingAttempts < remainingAttemptsBefore {
                return Effect(value: .wrongTransportPIN(remainingAttempts: remainingAttempts))
            }
            
            pinCallback(transportPIN, newPIN)
        case .requestCANAndChangedPIN:
            print("CAN to change PIN requested, so card is suspended. Callback not implemented yet.")
            return Effect(value: .error(ScanErrorState(errorType: .cardSuspended, retry: false)))
        case .requestPUK:
            print("PUK requested, so card is blocked. Callback not implemented yet.")
            return Effect(value: .error(ScanErrorState(errorType: .cardBlocked, retry: false)))
        default:
            environment.issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            print("Received unexpected event.")
            return Effect(value: .error(ScanErrorState(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct SetupScan: View {
    
    var store: Store<SetupScanState, SetupScanAction>
    
    init(store: Store<SetupScanState, SetupScanAction>) {
        self.store = store
    }
    
    var body: some View {
        SharedScan(store: store.scope(state: \.shared, action: SetupScanAction.shared),
                   instructionsTitle: L10n.FirstTimeUser.ScanInstructions.title,
                   instructionsBody: L10n.FirstTimeUser.ScanInstructions.body,
                   instructionsScanButtonTitle: L10n.FirstTimeUser.Scan.scan,
                   scanTitle: L10n.FirstTimeUser.Scan.title,
                   scanBody: L10n.FirstTimeUser.Scan.body,
                   scanButton: L10n.FirstTimeUser.Scan.scan)
            .onAppear {
                ViewStore(store).send(.onAppear)
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: SetupScanAction.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

struct SetupScan_Previews: PreviewProvider {
    
    static var previewReducer = Reducer<SetupScanState, SetupScanAction, AppEnvironment> { state, action, _ in
        switch action {
        case .shared(.startScan):
            state.shared.showInstructions.toggle()
            state.shared.isScanning.toggle()
            return .none
        default:
            return .none
        }
    }
    
    static var previews: some View {
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"), reducer: previewReducer, environment: AppEnvironment.preview))
            .previewDisplayName("Instructions")
        NavigationView {
            SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345",
                                                                newPIN: "123456",
                                                                shared: SharedScanState(isScanning: true,
                                                                                        showProgressCaption: ProgressCaption(title: L10n.FirstTimeUser.Scan.Progress.title,
                                                                                                                             body: L10n.FirstTimeUser.Scan.Progress.body),
                                                                                        showInstructions: false)),
                                   reducer: .empty,
                                   environment: AppEnvironment.preview))
            .previewDisplayName("Scanning")
        }
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456", shared: SharedScanState(showInstructions: false)), reducer: previewReducer, environment: AppEnvironment.preview))
            .previewDisplayName("Rescan")
    }
}
