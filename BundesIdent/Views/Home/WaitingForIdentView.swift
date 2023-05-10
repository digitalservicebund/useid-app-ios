import SwiftUI
import ComposableArchitecture

struct WaitingForIdent: ReducerProtocol {
    struct State: Equatable { }

    enum Action: Equatable {
        case task
        case triggerSetup
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .task:
                return .none
            default:
                return .none
            }
        }
    }
}

struct WaitingForIdentView: View {
    let store: Store<WaitingForIdent.State, WaitingForIdent.Action>
    
    var body: some View {
        NavigationView {
            VStack {
                Text(" o  o  o  o")
                    .bodyLBold(color: .blue800)
                    .padding(.bottom, 10)
                Text("Auf Identifikation warten")
                    .bodyLBold(color: .blue800)
            }
        }
    }
}

struct WaitingForIdentView_Previews: PreviewProvider {
    static var previews: some View {
        WaitingForIdentView(store: Store(initialState: WaitingForIdent.State(),
                              reducer: WaitingForIdent()))
    }
}
