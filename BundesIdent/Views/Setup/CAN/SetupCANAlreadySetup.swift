import SwiftUI
import ComposableArchitecture

struct SetupCANAlreadySetup: ReducerProtocol {
    struct State: Equatable {
        var tokenURL: URL?
        
        var message: String {
            if tokenURL == nil {
                return L10n.FirstTimeUser.Can.AlreadySetup.Body.setup
            } else {
                return L10n.FirstTimeUser.Can.AlreadySetup.Body.ident
            }
        }
        
        var primaryButton: DialogButtons<Action>.ButtonConfiguration {
            guard let tokenURL else {
                return .init(title: L10n.FirstTimeUser.Done.close,
                             action: .done)
            }
            
            return .init(title: L10n.FirstTimeUser.Done.identify,
                         action: .triggerIdentification(tokenURL: tokenURL))
        }
    }
    
    enum Action: Equatable {
        case missingPersonalPIN
        case done
        case triggerIdentification(tokenURL: URL)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct SetupCANAlreadySetupView: View {
    let store: StoreOf<SetupCANAlreadySetup>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WithViewStore(store) { viewStore in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HeaderView(title: L10n.FirstTimeUser.Can.AlreadySetup.title,
                                   message: viewStore.message)
                        HStack {
                            Button(L10n.Scan.helpNFC) {
                                viewStore.send(.missingPersonalPIN)
                            }
                            .buttonStyle(BundTextButtonStyle())
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
                DialogButtons(store: store.stateless,
                              primary: viewStore.primaryButton)
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SetupCANAlreadySetup_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupCANAlreadySetupView(store: .init(initialState: .init(),
                                                  reducer: EmptyReducer()))
        }
        .previewDisplayName("No redirect")
        NavigationView {
            SetupCANAlreadySetupView(store: .init(initialState: .init(tokenURL: URL(string: "https://example.org")!),
                                                  reducer: EmptyReducer()))
        }
        .previewDisplayName("Redirect")
    }
}
