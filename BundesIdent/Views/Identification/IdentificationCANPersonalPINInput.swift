import SwiftUI
import ComposableArchitecture

struct IdentificationCANPersonalPINInputState: Equatable {
    @BindableState var enteredPIN: String = ""
    let request: EIDAuthenticationRequest
    var pinCANCallback: PINCANCallback
    var doneButtonEnabled: Bool {
        return enteredPIN.count == Constants.PERSONAL_PIN_DIGIT_COUNT
    }
}

enum IdentificationCANPersonalPINInputAction: Equatable, BindableAction {
    case done(pin: String, request: EIDAuthenticationRequest, pinCANCallback: PINCANCallback)
    case binding(BindingAction<IdentificationCANPersonalPINInputState>)
}

var identificationCANPersonalPINInputReducer = Reducer<IdentificationCANPersonalPINInputState, IdentificationCANPersonalPINInputAction, AppEnvironment>.init { _, action, _ in
    switch action {
    default:
        return .none
    }
}.binding()

struct IdentificationCANPersonalPINInput: View {
    var store: Store<IdentificationCANPersonalPINInputState, IdentificationCANPersonalPINInputAction>
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
                                viewStore.send(.done(pin: pin, request: viewStore.request, pinCANCallback: viewStore.pinCANCallback))
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
            IdentificationCANPersonalPINInput(store: .init(initialState: .init(request: .preview, pinCANCallback: .init(id: UUID(), callback: { _, _ in })),
                                                           reducer: identificationCANPersonalPINInputReducer,
                                                           environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
