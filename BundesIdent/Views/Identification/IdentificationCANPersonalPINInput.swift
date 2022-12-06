import SwiftUI
import ComposableArchitecture

struct IdentificationCANPersonalPINInput: ReducerProtocol {
    struct State: Equatable {
        @BindableState var enteredPIN: String = ""
        let request: EIDAuthenticationRequest
        var doneButtonEnabled: Bool {
            return enteredPIN.count == Constants.PERSONAL_PIN_DIGIT_COUNT
        }
    }

    enum Action: Equatable, BindableAction {
        case done(pin: String, request: EIDAuthenticationRequest)
        case binding(BindingAction<IdentificationCANPersonalPINInput.State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
    }
}

struct IdentificationCANPersonalPINInputView: View {
    var store: Store<IdentificationCANPersonalPINInput.State, IdentificationCANPersonalPINInput.Action>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.Identification.PersonalPIN.title)
                        .headingXL()
                    VStack {
                        Spacer()
                        WithViewStore(store) { viewStore in
                            PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                         maxDigits: Constants.PERSONAL_PIN_DIGIT_COUNT,
                                         groupEvery: 3,
                                         showPIN: false,
                                         label: L10n.Identification.PersonalPIN.textFieldLabel,
                                         backgroundColor: .neutral100,
                                         doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                              title: L10n.Identification.PersonalPIN.continue,
                                                                              handler: { pin in
                                viewStore.send(.done(pin: pin, request: viewStore.request))
                            }))
                            .focused($pinEntryFocused)
                            .headingL()
                        }
                    }
                    
                    Text(L10n.Identification.PersonalPIN.Error.Incorrect.remainingAttemptsLld(1))
                        .bodyLRegular()
                        .multilineTextAlignment(.center)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                pinEntryFocused = true
            }
        }
        .interactiveDismissDisabled(true)
    }
}

struct IdentificationCANPersonalPINInput_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationCANPersonalPINInputView(store: .init(initialState: .init(request: .preview),
                                                           reducer: IdentificationCANPersonalPINInput()))
        }
        .previewDevice("iPhone 12")
    }
}
