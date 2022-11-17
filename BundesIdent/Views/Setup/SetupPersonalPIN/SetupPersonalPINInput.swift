import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPINInput: View {
    var store: Store<SetupPersonalPINInputState, SetupPersonalPINInputAction>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.FirstTimeUser.PersonalPIN.title,
                               message: L10n.FirstTimeUser.PersonalPIN.body)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                     maxDigits: Constants.PERSONAL_PIN_DIGIT_COUNT,
                                     groupEvery: 3,
                                     showPIN: false,
                                     label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first,
                                     backgroundColor: .gray100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.FirstTimeUser.PersonalPIN.continue,
                                                                          handler: { _ in
                            viewStore.send(.done(pin: viewStore.enteredPIN))
                        }))
                        .focused($pinEntryFocused)
                        .font(.bundTitle)
                    }
                    Spacer()
                }
                .focusOnAppear {
                    pinEntryFocused = true
                }
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .padding(.horizontal)
        }
        .interactiveDismissDisabled()
    }
}

struct SetupPersonalPINInput_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupPersonalPINInput(store: Store(initialState: SetupPersonalPINInputState(enteredPIN: "12345"),
                                          reducer: .empty,
                                          environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
