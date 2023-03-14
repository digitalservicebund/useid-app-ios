import ComposableArchitecture
import SwiftUI

struct SetupCANAlreadySetup: ReducerProtocol {
    struct State: Equatable {
        var identificationInformation: IdentificationInformation?
        
        var message: String {
            if identificationInformation == nil {
                return L10n.FirstTimeUser.Can.AlreadySetup.Body.setup
            } else {
                return L10n.FirstTimeUser.Can.AlreadySetup.Body.ident
            }
        }
        
        var primaryButton: DialogButtons<Action>.ButtonConfiguration {
            guard let identificationInformation else {
                return .init(title: L10n.FirstTimeUser.Done.close,
                             action: .done)
            }
            
            return .init(title: L10n.FirstTimeUser.Done.identify,
                         action: .triggerIdentification(identificationInformation: identificationInformation))
        }
    }
    
    enum Action: Equatable {
        case missingPersonalPIN
        case done
        case triggerIdentification(identificationInformation: IdentificationInformation)
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
                            Button(L10n.FirstTimeUser.Can.AlreadySetup.personalPINNotAvailable) {
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
            SetupCANAlreadySetupView(store: .init(initialState: .init(identificationInformation: .preview),
                                                  reducer: EmptyReducer()))
        }
        .previewDisplayName("Redirect")
    }
}
