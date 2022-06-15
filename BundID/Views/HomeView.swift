import SwiftUI
import ComposableArchitecture

struct HomeState: Equatable {
    var tokenURL: String?
}

enum HomeAction: Equatable {
    case triggerSetup
    case triggerIdentification(tokenURL: String)
}

struct HomeView: View {
    
    var store: Store<HomeState, HomeAction>
    
    var body: some View {
        VStack {
            WithViewStore(store) { viewStore in
                VStack(spacing: 24) {
                    if let tokenURL = viewStore.tokenURL {
                        Button {
                            viewStore.send(.triggerIdentification(tokenURL: tokenURL))
                        } label: {
                            Text("Identifizierung erneut starten")
                        }
                    }
                    Button {
                        viewStore.send(.triggerSetup)
                    } label: {
                        Text("Einrichtung starten")
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(store: Store(initialState: .init(), reducer: .empty, environment: AppEnvironment.preview))
    }
}
