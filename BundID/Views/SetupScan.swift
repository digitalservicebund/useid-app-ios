import SwiftUI
import ComposableArchitecture
import Combine
import Lottie

enum SetupScanError: Equatable {
    case idCardInteraction(IDCardInteractionError)
}

struct SetupScanState: Equatable {
    var error: SetupScanError?
}

enum SetupScanAction: Equatable {
    case onAppear
    case startScan
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
}

struct ScanEffect: Hashable { let id: AnyHashable }

let setupScanReducer = Reducer<SetupScanState, SetupScanAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        return Effect(value: .startScan)
    case .startScan:
        return environment.idInteractionManager.changePIN()
            .receive(on: environment.mainQueue)
            .catchToEffect(SetupScanAction.scanEvent)
    case .scanEvent(.failure(let error)):
        state.error = .idCardInteraction(error)
        return .none
    case .scanEvent(.success(let event)):
        return .none
    }
}

struct SetupScan: View {
    
    var store: Store<SetupScanState, SetupScanAction>
    
    var body: some View {
        WithViewStore(store.stateless) { viewStore in
            VStack {
                LottieView(name: "38076-id-scan")
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                Spacer()
                DialogButtons(store: store.stateless,
                              secondary: nil,
                              primary: .init(title: "Start scanning", action: .startScan))
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
