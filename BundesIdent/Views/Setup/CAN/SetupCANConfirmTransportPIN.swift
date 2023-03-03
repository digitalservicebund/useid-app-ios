import SwiftUI
import ComposableArchitecture

struct SetupCANConfirmTransportPIN: ReducerProtocol {
    struct State: Equatable {
        let transportPIN: String
    }
    
    enum Action: Equatable {
        case confirm
        case edit
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct SetupCANConfirmTransportPINView: View {
    let store: StoreOf<SetupCANConfirmTransportPIN>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WithViewStore(store.scope(state: \.transportPIN)) { transportPIN in
            DialogView(store: store.stateless,
                       title: L10n.FirstTimeUser.Can.ConfirmTransportPIN.title(transportPIN.state),
                       message: L10n.FirstTimeUser.Can.ConfirmTransportPIN.Body.ios(transportPIN.state),
                       secondaryButton: .init(title: L10n.FirstTimeUser.Can.ConfirmTransportPIN.incorrectInput, action: .edit),
                       primaryButton: .init(title: L10n.FirstTimeUser.Can.ConfirmTransportPIN.confirmInput, action: .confirm))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.General.cancel) {
                            dismiss()
                        }
                        .bodyLRegular(color: .accentColor)
                    }
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false)
    }
}

struct SetupCANConfirmTransportPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupCANConfirmTransportPINView(store: .init(initialState: .init(transportPIN: "123456"),
                                                         reducer: EmptyReducer()))
        }
    }
}
