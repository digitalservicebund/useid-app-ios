import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPINConfirm: View {
    var store: Store<SetupPersonalPINConfirmState, SetupPersonalPINConfirmAction>
    @FocusState private var pinEntryFocused: Bool
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.FirstTimeUser.PersonalPIN.Confirmation.title,
                               message: L10n.FirstTimeUser.PersonalPIN.Confirmation.body)
                    VStack {
                        Spacer()
                        VStack {
                            PINEntryView(pin: viewStore.binding(\.$enteredPIN2),
                                         maxDigits: Constants.PERSONAL_PIN_DIGIT_COUNT,
                                         groupEvery: 3,
                                         showPIN: false,
                                         label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second,
                                         backgroundColor: .gray100,
                                         doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                              title: L10n.FirstTimeUser.PersonalPIN.continue,
                                                                              handler: { _ in
                                viewStore.send(.checkPINs)
                            }))
                            .focused($pinEntryFocused)
                            .font(.bundTitle)
                            Spacer()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer()
                }
                .focusOnAppear {
                    pinEntryFocused = true
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
        .interactiveDismissDisabled()
    }
}

struct SetupPersonalPINConfirm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupPersonalPINConfirm(store: Store(initialState: SetupPersonalPINConfirmState(enteredPIN1: "12345"),
                                                 reducer: .empty,
                                                 environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
