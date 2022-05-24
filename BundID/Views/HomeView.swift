import SwiftUI
import ComposableArchitecture

enum HomeAction: Equatable {
    case triggerSetup
}

struct HomeView: View {
    
    var store: Store<Void, HomeAction>
    
    var body: some View {
        VStack {
            WithViewStore(store) { viewStore in
                Button {
                    viewStore.send(.triggerSetup)
                } label: {
                    Text("Einrichtung starten")
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(store: Store(initialState: (), reducer: .empty, environment: AppEnvironment.preview))
    }
}
