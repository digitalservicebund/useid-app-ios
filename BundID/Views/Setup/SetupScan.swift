import SwiftUI
import ComposableArchitecture
import Combine
import Lottie
import Analytics

enum SetupScanError: Error, Equatable {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct SetupScanState: Equatable {
    var isScanning: Bool = false
    var scanAvailable: Bool = true
    var showProgressCaption: Bool = false
    var transportPIN: String
    var newPIN: String
    var remainingAttempts: Int?
    var attempt = 0
    var alert: AlertState<SetupScanAction>?
#if PREVIEW
    var availableDebugActions: [ChangePINDebugSequence] = []
#endif
}

extension SetupScanState: AnalyticsView {
     var route: [String] {
         guard let error = error else { return [] }
         
         switch error {
          case .idCardInteraction(let idCardInteractionError):
             return ["idCardInteraction"] // + idCardInteractionError.route
          case .unexpectedEvent(let eIDInteractionEvent):
             return ["unexpectedEvent"] //+ eIDInteractionEvent.route
          }
     }
 }

enum SetupScanAction: Equatable {
    case onAppear
    case startScan
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case wrongTransportPIN(remainingAttempts: Int)
    case error(ScanErrorState)
    case cancelScan
    case scannedSuccessfully
    case showNFCInfo
    case dismissAlert
    case showHelp
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
    case .startScan:
        guard !state.isScanning else { return .none }
        state.isScanning = true
        
        let publisher: EIDInteractionPublisher
#if PREVIEW
        if MOCK_OPENECARD {
            let debuggableInteraction = environment.debugIDInteractionManager.debuggableChangePIN()
            state.availableDebugActions = debuggableInteraction.sequence
            publisher = debuggableInteraction.publisher
        } else {
            publisher = environment.idInteractionManager.changePIN(nfcMessages: .setup)
        }
#else
        publisher = environment.idInteractionManager.changePIN(nfcMessages: .setup)
#endif
        return publisher
            .receive(on: environment.mainQueue)
            .catchToEffect(SetupScanAction.scanEvent)
            .cancellable(id: CancelId.self, cancelInFlight: true)
    case .scanEvent(.failure(let error)):
        state.isScanning = false
        
        switch error {
        case .cardDeactivated:
            state.scanAvailable = false
            return Effect(value: .error(ScanErrorState(errorType: .cardDeactivated, retry: state.scanAvailable)))
        case .cardBlocked:
            state.scanAvailable = false
            return Effect(value: .error(ScanErrorState(errorType: .cardBlocked, retry: state.scanAvailable)))
        default:
            state.scanAvailable = true
            return Effect(value: .error(ScanErrorState(errorType: .idCardInteraction(error), retry: state.scanAvailable)))
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
    case .showNFCInfo:
        state.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                 message: TextState(L10n.HelpNFC.body),
                                 dismissButton: .cancel(TextState(L10n.General.ok),
                                                        action: .send(.dismissAlert)))
        return .none
    case .showHelp:
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
        case .requestCardInsertion(let messageCallback):
            self.showProgressCaption = false
            messageCallback(L10n.FirstTimeUser.Scan.scanningCard)
        case .cardInteractionComplete: print("Card interaction complete.")
        case .cardRecognized: print("Card recognized.")
        case .cardRemoved:
            self.showProgressCaption = true
            print("Card removed.")
        case .processCompletedSuccessfullyWithoutRedirect:
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
            return Effect(value: .error(ScanErrorState(errorType: .cardSuspended, retry: false)))
        case .requestPUK:
            print("PUK requested, so card is blocked. Callback not implemented yet.")
            return Effect(value: .error(ScanErrorState(errorType: .cardBlocked, retry: false)))
        default:
            print("Received unexpected event.")
            return Effect(value: .error(ScanErrorState(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct SetupScan: View {
    
    var store: Store<SetupScanState, SetupScanAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    LottieView(name: Asset.animationIdScan.name,
                               backgroundColor: Color(0xEBEFF2),
                               accessiblityLabel: L10n.Scan.animationAccessibilityLabel)
                        .aspectRatio(540.0 / 367.0, contentMode: .fit)
                    
                    if viewStore.isScanning {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                                .scaleEffect(3)
                                .frame(maxWidth: .infinity)
                                .padding(50)
                            if viewStore.showProgressCaption {
                                VStack(spacing: 24) {
                                    Text(L10n.FirstTimeUser.Scan.Progress.title)
                                        .font(.bundTitle)
                                        .foregroundColor(.blackish)
                                    Text(L10n.FirstTimeUser.Scan.Progress.body)
                                        .font(.bundBody)
                                        .foregroundColor(.blackish)
                                }
                                .padding(.bottom, 50)
                            }
                        }
                    } else {
                        ScanBody(title: L10n.FirstTimeUser.Scan.title,
                                 message: L10n.FirstTimeUser.Scan.body,
                                 buttonTitle: L10n.FirstTimeUser.Scan.scan,
                                 buttonTapped: { viewStore.send(.startScan) },
                                 nfcInfoTapped: { viewStore.send(.showNFCInfo) },
                                 helpTapped: { viewStore.send(.showHelp) })
                        .disabled(!viewStore.scanAvailable)
                    }
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
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

struct SetupScan_Previews: PreviewProvider {
    static var previews: some View {
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"), reducer: .empty, environment: AppEnvironment.preview))
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"), reducer: .empty, environment: AppEnvironment.preview))
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"), reducer: .empty, environment: AppEnvironment.preview))
        NavigationView {
            SetupScan(store: Store(initialState: SetupScanState(isScanning: true, showProgressCaption: false, transportPIN: "12345", newPIN: "123456"), reducer: .empty, environment: AppEnvironment.preview))
        }
    }
}
