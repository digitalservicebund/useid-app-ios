import SwiftUI
import ComposableArchitecture
import Combine
import Lottie

enum SetupScanError: Equatable {
    case idCardInteraction(IDCardInteractionError)
}

struct SetupScanState: Equatable {
    var scanAvailable: Bool = true
    var error: SetupScanError?
}

enum SetupScanAction: Equatable {
    case onAppear
    case startScan
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case cancelScan
}

let setupScanReducer = Reducer<SetupScanState, SetupScanAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        return Effect(value: .startScan)
    case .startScan:
        state.scanAvailable = false
        return environment.idInteractionManager.changePIN()
            .catchToEffect(SetupScanAction.scanEvent)
            .cancellable(id: "ChangePIN", cancelInFlight: true)
    case .scanEvent(.failure(let error)):
        state.error = .idCardInteraction(error)
        state.scanAvailable = true
        return .none
    case .scanEvent(.success(let value)):
        switch value {
        case .authenticationStarted: print("Authentication started")
        case .requestCardInsertion(let messageCallback):
            print("Request card insertion.")
            messageCallback("Request card insertion.")
        case .cardInteractionComplete: print("Card interaction complete.")
        case .cardRecognized: print("Card recognized.")
        case .cardRemoved: print("Card removed.")
        case .requestCAN(let canCallback): print("CAN callback not implemented.")
        case .requestPIN(let attempts, let pinCallback): print("PIN callback not implemented.")
        case .requestPINAndCAN(let pinCANCallback): print("PIN CAN callback not implemented.")
        case .requestPUK(let pukCallback): print("PUK callback not implemented.")
        case .processCompletedSuccessfully: print("Process completed successfully.")
        case .pinManagementStarted: print("PIN Management started.")
        case .requestChangedPIN(let attempts, let pinCallback):
            print("Providing changed PIN with \(attempts ?? 3) attempts.")
            
            // This is our signal that the user canceled (for now)
            guard attempts != nil else {
                return Effect(value: .cancelScan)
            }
            
            pinCallback("123456", "000000")
        case .requestCANAndChangedPIN(let pinCallback): print("Providing CAN and changed PIN not implemented.")
        default: print("Received unexpected event.")
        }
        return .none
    case .cancelScan:
        state.scanAvailable = true
        return .cancel(id: "ChangePIN")
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
                DialogButtons(store: store.stateless,
                              secondary: nil,
                              primary: .init(title: "Start scanning", action: .startScan))
                .disabled(!viewStore.scanAvailable)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

struct SetupScan_Previews: PreviewProvider {
    static var previews: some View {
        SetupScan(store: Store(initialState: SetupScanState(), reducer: .empty, environment: AppEnvironment.preview))
    }
}
