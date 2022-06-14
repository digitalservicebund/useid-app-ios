import SwiftUI
import ComposableArchitecture

enum HomeAction: Equatable {
    case triggerSetup
    case triggerIdentification(tokenURL: String)
}

struct HomeView: View {
    
    var store: Store<Void, HomeAction>
    
    var body: some View {
        VStack {
            WithViewStore(store) { viewStore in
                VStack {
                    Button {
                        viewStore.send(.triggerSetup)
                    } label: {
                        Text("Einrichtung starten")
                    }
                    Button {
                        viewStore.send(.triggerIdentification(tokenURL: demoTokenURL))
                    } label: {
                        Text("Identifizierung starten")
                    }
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
