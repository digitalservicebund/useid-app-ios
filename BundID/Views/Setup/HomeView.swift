import SwiftUI
import ComposableArchitecture

struct HomeState: Equatable {
    var appVersion: String
    var buildNumber: Int
    var tokenURL: String?
}

enum HomeAction: Equatable {
    case triggerSetup
    case triggerIdentification(tokenURL: String)
}

struct HomeView: View {
    
    var store: Store<HomeState, HomeAction>
    
    var body: some View {
        NavigationView {
            VStack {
                WithViewStore(store) { viewStore in
                    VStack {
                        Spacer()
                        VStack(spacing: 24) {
                            if let tokenURL = viewStore.tokenURL {
                                Button {
                                    viewStore.send(.triggerIdentification(tokenURL: tokenURL))
                                } label: {
                                    Text("Identifizierung erneut starten")
                                }
                            }
#if PREVIEW
                            Button {
                                viewStore.send(.triggerIdentification(tokenURL: demoTokenURL))
                            } label: {
                                Text("Identifizierung (Demo) starten")
                            }
#endif
                            Button {
                                viewStore.send(.triggerSetup)
                            } label: {
                                Text("Einrichtung starten")
                            }
                        }
                        Spacer()
                        Text("Version: \(viewStore.appVersion) - \(viewStore.buildNumber) (\(environment))")
                            .font(.bundCaption2)
                    }
                }
            }
        }
    }
    
    var environment: String {
#if PREVIEW
        return "PREVIEW"
#else
        return "PRODUCTION"
#endif
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(store: Store(initialState: HomeState(appVersion: "1.2.3",
                                                      buildNumber: 42),
                              reducer: .empty,
                              environment: AppEnvironment.preview))
    }
}
