import SwiftUI
import ComposableArchitecture
import Combine

struct SetupScanState: Equatable {
    
}

enum SetupScanAction: Equatable {
    case onAppear
    case startScan
    case scanee(EIDInteractionEvent)
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
}

struct ScanEffect: Hashable { let id: AnyHashable }

let setupScanReducer = Reducer<SetupScanState, SetupScanAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        return Effect(value: .startScan)
    case .scanee(let event):
        print(event)
        return .none
    case .startScan:
        return environment.idInteractionManager.changePIN()
            .receive(on: environment.mainQueue)
            .catchToEffect(SetupScanAction.scanEvent)
    case .scanEvent(let result):
        print(result)
        return .none
    }
}

struct SetupScan: View {
    
    var store: Store<SetupScanState, SetupScanAction>
    
    var body: some View {
        WithViewStore(store.stateless) { viewStore in
            VStack {
                Image("eIDs")
                    .resizable()
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
