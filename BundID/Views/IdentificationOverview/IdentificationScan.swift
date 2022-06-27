import SwiftUI
import ComposableArchitecture
import Combine
import Lottie

enum IdentificationScanError: Equatable {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct IdentificationScanState: Equatable {
    var isScanning: Bool = false
    var showProgressCaption: Bool = false
    var tokenURL: String
    var pin: String
    var error: IdentificationScanError?
    var remainingAttempts: Int?
    var attempt = 0
#if MOCK_OPENECARD
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
}

enum IdentificationScanAction: Equatable {
    case onAppear
    case startScan
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case wrongPIN(remainingAttempts: Int)
    case error(CardErrorType)
    case cancelScan
    case scannedSuccessfully
#if MOCK_OPENECARD
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

let identificationScanReducer = Reducer<IdentificationScanState, IdentificationScanAction, AppEnvironment> { state, action, environment in
    
    enum IdentifyId {}
    
    switch action {
#if MOCK_OPENECARD
    case .runDebugSequence(let debugSequence):
        // swiftlint:disable:next force_cast
        let debugInteractionManager = (environment.idInteractionManager as! DebugIDInteractionManager)
        state.availableDebugActions = debugInteractionManager.runIdentify(debugSequence: debugSequence)
        return .none
#endif
    case .onAppear:
        return Effect(value: .startScan)
    case .startScan:
        state.error = nil
        state.isScanning = true
        
#if MOCK_OPENECARD
        // swiftlint:disable:next force_cast
        let debugIDInteractionManager = environment.idInteractionManager as! DebugIDInteractionManager
        let debuggableInteraction = debugIDInteractionManager.debuggableIdentify(tokenURL: state.tokenURL)
        state.availableDebugActions = debuggableInteraction.sequence
        return debuggableInteraction.publisher
            .receive(on: environment.mainQueue)
            .catchToEffect(IdentificationScanAction.scanEvent)
            .cancellable(id: IdentifyId.self, cancelInFlight: true)
        
#else
        return environment.idInteractionManager.identify(tokenURL: state.tokenURL)
            .receive(on: environment.mainQueue)
            .catchToEffect(IdentificationScanAction.scanEvent)
            .cancellable(id: IdentifyId.self, cancelInFlight: true)
#endif
    case .scanEvent(.failure(let error)):
        state.error = .idCardInteraction(error)
        state.isScanning = false
        
        switch error {
        case .cardDeactivated:
            return Effect(value: .error(.cardDeactivated))
        case .cardBlocked:
            return Effect(value: .error(.cardBlocked))
        default:
            return .cancel(id: IdentifyId.self)
        }
    case .scanEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .cancelScan:
        state.isScanning = false
        return .cancel(id: IdentifyId.self)
    case .error:
        return .cancel(id: IdentifyId.self)
    case .wrongPIN:
        return .cancel(id: IdentifyId.self)
    case .scannedSuccessfully:
        return .cancel(id: IdentifyId.self)
    }
}

extension IdentificationScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<IdentificationScanAction, Never> {
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
        case .requestPIN(let remainingAttempts, let pinCallback):
            print("Providing changed PIN with \(remainingAttempts ?? 3) remaining attempts.")
            let remainingAttemptsBefore = self.remainingAttempts
            self.remainingAttempts = remainingAttempts
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = remainingAttempts else {
                return Effect(value: .cancelScan)
            }
            
            // Wrong transport/personal PIN provided
            if let remainingAttemptsBefore = remainingAttemptsBefore,
               remainingAttempts < remainingAttemptsBefore {
                return Effect(value: .wrongPIN(remainingAttempts: remainingAttempts))
            }
            
            pinCallback(pin)
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

extension IdentificationScanState {
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

struct IdentificationScan: View {
    
    var store: Store<IdentificationScanState, IdentificationScanAction>
    
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
#if MOCK_OPENECARD
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        ForEach(viewStore.availableDebugActions) { sequence in
                            Button(sequence.id) {
                                viewStore.send(.runDebugSequence(sequence))
                            }
                        }
                    } label: {
                        Image(systemName: "wrench")
                    }.disabled(!viewStore.isScanning)
                }
            }
#endif
        }
    }
}

struct IdentificationScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationScan(store: Store(initialState: IdentificationScanState(tokenURL: demoTokenURL, pin: "123456"), reducer: .empty, environment: AppEnvironment.preview))
        IdentificationScan(store: Store(initialState: IdentificationScanState(isScanning: true, tokenURL: demoTokenURL, pin: "123456"), reducer: .empty, environment: AppEnvironment.preview))
    }
}
