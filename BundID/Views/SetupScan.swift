import SwiftUI
import ComposableArchitecture
import Combine
import Lottie

enum SetupScanError: Equatable {
    case idCardInteraction(IDCardInteractionError)
}

struct SetupScanState: Equatable {
    var scanAvailable: Bool = true
    var transportPIN: String
    var newPIN: String
    var error: SetupScanError?
    var remainingAttempts: Int?
    var attempt = 0
}

enum SetupScanAction: Equatable {
    case onAppear
    case startScan
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case wrongTransportPIN(remainingAttempts: Int)
    case cancelScan
    case scannedSuccessfully
#if targetEnvironment(simulator)
    case runDebugSequence(DebugIDInteractionManager.DebugSequence)
#endif
}

let setupScanReducer = Reducer<SetupScanState, SetupScanAction, AppEnvironment> { state, action, environment in
    switch action {
#if targetEnvironment(simulator)
    case .runDebugSequence(let debugSequence):
        // swiftlint:disable:next force_cast
        (environment.idInteractionManager as! DebugIDInteractionManager).runDebugSequence(debugSequence)
        return .none
#endif
    case .onAppear:
        return Effect(value: .startScan)
    case .startScan:
        state.scanAvailable = false
        return environment.idInteractionManager.changePIN()
            .receive(on: environment.mainQueue)
            .catchToEffect(SetupScanAction.scanEvent)
            .cancellable(id: "ChangePIN", cancelInFlight: true)
    case .scanEvent(.failure(let error)):
        state.error = .idCardInteraction(error)
        state.scanAvailable = true
        return .none
    case .scanEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .cancelScan:
        state.scanAvailable = true
        return .cancel(id: "ChangePIN")
    case .wrongTransportPIN:
        return .cancel(id: "ChangePIN")
    case .scannedSuccessfully:
        return .none
    }
}

extension SetupScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<SetupScanAction, Never> {
        switch event {
        case .authenticationStarted:
            print("Authentication started")
        case .requestCardInsertion(let messageCallback):
            print("Request card insertion.")
            messageCallback("Request card insertion.")
        case .cardInteractionComplete: print("Card interaction complete.")
        case .cardRecognized: print("Card recognized.")
        case .cardRemoved: print("Card removed.")
        case .requestCAN(let canCallback): print("CAN callback not implemented.")
        case .requestPIN(let remainingAttempts, let pinCallback): print("PIN callback not implemented.")
        case .requestPINAndCAN(let pinCANCallback): print("PIN CAN callback not implemented.")
        case .requestPUK(let pukCallback): print("PUK callback not implemented.")
        case .processCompletedSuccessfully:
            return Effect(value: .scannedSuccessfully)
        case .pinManagementStarted: print("PIN Management started.")
        case .requestChangedPIN(let remainingAttempts, let pinCallback):
            print("Providing changed PIN with \(remainingAttempts ?? 3) remaining attempts.")
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = remainingAttempts else {
                return Effect(value: .cancelScan)
            }
            
            if self.remainingAttempts == nil {
                self.remainingAttempts = remainingAttempts
            }
            
            // Wrong transport/personal PIN provided
            if self.remainingAttempts != remainingAttempts {
                return Effect(value: .wrongTransportPIN(remainingAttempts: remainingAttempts))
            }
            
            pinCallback(transportPIN, newPIN)
        case .requestCANAndChangedPIN(let pinCallback):
            print("Providing CAN and changed PIN not implemented.")
        default: print("Received unexpected event.")
        }
        return .none
    }
}

struct SetupScan: View {
    
    var store: Store<SetupScanState, SetupScanAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack {
                LottieView(name: "38076-id-scan")
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                Spacer()
#if targetEnvironment(simulator)
                HStack {
                    Button("NFC Error", action: {
                        viewStore.send(.runDebugSequence(.runNFCError))
                    }).padding(5).background(Color.red).cornerRadius(8)
                    Button("Incorrect transport PIN", action: {
                        viewStore.send(.runDebugSequence(.runTransportPINError))
                    }).padding(5).background(Color.red).cornerRadius(8)
                    Button("Success", action: {
                        viewStore.send(.runDebugSequence(.runSuccessfully))
                    }).padding(5).background(Color.green).cornerRadius(8)
                }.padding()
#endif
                DialogButtons(store: store.stateless,
                              secondary: nil,
                              primary: .init(title: "Start scanning", action: .startScan))
                .disabled(!viewStore.scanAvailable)
            }.onChange(of: viewStore.state.attempt, perform: { _ in
                viewStore.send(.startScan)
            })
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct SetupScan_Previews: PreviewProvider {
    static var previews: some View {
        SetupScan(store: Store(initialState: SetupScanState(transportPIN: "12345", newPIN: "123456"), reducer: .empty, environment: AppEnvironment.preview))
    }
}
