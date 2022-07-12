import SwiftUI
import ComposableArchitecture
import Combine
import Lottie

enum SetupScanError: Equatable {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct SetupScanState: Equatable {
    var isScanning: Bool = false
    var showProgressCaption: Bool = false
    var transportPIN: String
    var newPIN: String
    var error: SetupScanError?
    var remainingAttempts: Int?
    var attempt = 0
#if PREVIEW
    var availableDebugActions: [ChangePINDebugSequence] = []
#endif
}

enum SetupScanAction: Equatable {
    case onAppear
    case startScan
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case wrongTransportPIN(remainingAttempts: Int)
    case error(CardErrorType)
    case cancelScan
    case scannedSuccessfully
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
        return Effect(value: .startScan)
    case .startScan:
        state.error = nil
        state.isScanning = true
    
        let publisher: EIDInteractionPublisher
#if PREVIEW
        if MOCK_OPENECARD {
            let debuggableInteraction = environment.debugIDInteractionManager.debuggableChangePIN()
            state.availableDebugActions = debuggableInteraction.sequence
            publisher = debuggableInteraction.publisher
        } else {
            publisher = environment.idInteractionManager.changePIN()
        }
#else
        publisher = environment.idInteractionManager.changePIN()
#endif
        return publisher
            .receive(on: environment.mainQueue)
            .catchToEffect(SetupScanAction.scanEvent)
            .cancellable(id: CancelId.self, cancelInFlight: true)
    case .scanEvent(.failure(let error)):
        state.error = .idCardInteraction(error)
        state.isScanning = false
        
        switch error {
        case .cardDeactivated:
            return Effect(value: .error(.cardDeactivated))
        case .cardBlocked:
            return Effect(value: .error(.cardBlocked))
        default:
            return .cancel(id: CancelId.self)
        }
    case .scanEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .cancelScan:
        state.isScanning = false
        return .cancel(id: CancelId.self)
    case .error:
        return .cancel(id: CancelId.self)
    case .wrongTransportPIN:
        return .cancel(id: CancelId.self)
    case .scannedSuccessfully:
        return .cancel(id: CancelId.self)
    }
}

extension SetupScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<SetupScanAction, Never> {
        switch event {
        case .authenticationStarted:
            print("Authentication started")
        case .requestCardInsertion(let messageCallback):
            self.showProgressCaption = false
            print("Request card insertion.")
            messageCallback("Request card insertion.")
        case .cardInteractionComplete: print("Card interaction complete.")
        case .cardRecognized: print("Card recognized.")
        case .cardRemoved:
            self.showProgressCaption = true
            print("Card removed.")
        case .processCompletedSuccessfully:
            return Effect(value: .scannedSuccessfully)
        case .pinManagementStarted: print("PIN Management started.")
        case .requestChangedPIN(let remainingAttempts, let pinCallback):
            print("Providing changed PIN with \(String(describing: remainingAttempts)) remaining attempts.")
            let remainingAttemptsBefore = self.remainingAttempts
            self.remainingAttempts = remainingAttempts
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = remainingAttempts else {
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
            return Effect(value: .error(.cardSuspended))
        case .requestPUK:
            print("PUK requested, so card is blocked. Callback not implemented yet.")
            return Effect(value: .error(.cardBlocked))
        default:
            self.error = .unexpectedEvent(event)
            print("Received unexpected event.")
            return Effect(value: .cancelScan)
        }
        return .none
    }
}

extension SetupScanState {
    var errorTitle: String? {
        switch self.error {
        case .idCardInteraction:
            return L10n.FirstTimeUser.Scan.ScanError.IdCardInteraction.title
        case .unexpectedEvent:
            return L10n.FirstTimeUser.Scan.ScanError.UnexpectedEvent.title
        default:
            return nil
        }
    }

    var errorBody: String? {
        switch self.error {
        case .idCardInteraction:
            return L10n.FirstTimeUser.Scan.ScanError.IdCardInteraction.body
        case .unexpectedEvent:
            return L10n.FirstTimeUser.Scan.ScanError.UnexpectedEvent.body
        default:
            return nil
        }
    }
    
    var showLottie: Bool {
        switch self.error {
        case .unexpectedEvent:
            return false
        default:
            return true
        }
    }
}

struct SetupScan: View {
    
    var store: Store<SetupScanState, SetupScanAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    if viewStore.state.showLottie {
                        LottieView(name: "38076-id-scan")
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        Spacer()
                    }
                    
                    if let title = viewStore.state.errorTitle {
                        HeaderView(title: title, message: viewStore.state.errorBody)
                    }
                }
                if viewStore.isScanning {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                            .scaleEffect(3)
                            .frame(maxWidth: .infinity)
                            .padding(50)
                        if viewStore.showProgressCaption {
                        	Text(L10n.FirstTimeUser.Scan.Progress.caption)
                            	.font(.bundTitle)
                            	.foregroundColor(.blackish)
                                .padding(.bottom, 50)
                        }
                    }
                } else {
                    DialogButtons(store: store.stateless,
                                  secondary: nil,
                                  primary: .init(title: L10n.FirstTimeUser.Scan.scan, action: .startScan))
                    .disabled(viewStore.isScanning)
                }
            }.onChange(of: viewStore.state.attempt, perform: { _ in
                viewStore.send(.startScan)
            })
            .onAppear {
                viewStore.send(.onAppear)
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: SetupScanAction.runDebugSequence)
#endif
        }
    }
}

struct SetupScan_Previews: PreviewProvider {
    static var previews: some View {
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"), reducer: .empty, environment: AppEnvironment.preview))
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456", error: .idCardInteraction(.processFailed(resultCode: .INTERNAL_ERROR))), reducer: .empty, environment: AppEnvironment.preview))
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456", error: .unexpectedEvent(.requestPINAndCAN({ _, _ in }))), reducer: .empty, environment: AppEnvironment.preview))
        NavigationView {
            SetupScan(store: Store(initialState: SetupScanState(isScanning: true, showProgressCaption: false, transportPIN: "12345", newPIN: "123456"), reducer: .empty, environment: AppEnvironment.preview))
        }
    }
}
