import SwiftUI
import ComposableArchitecture

struct IdentificationCANInput: ReducerProtocol {
    struct State: Equatable {
        @BindableState var enteredCAN: String = ""
        let request: EIDAuthenticationRequest
        var pushesToPINEntry: Bool
        var doneButtonEnabled: Bool {
            return enteredCAN.count == Constants.CAN_DIGIT_COUNT
        }
    }
    
    enum Action: Equatable, BindableAction {
        case done(can: String, request: EIDAuthenticationRequest, pushesToPINEntry: Bool)
        case binding(BindingAction<IdentificationCANInput.State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
    }
}

struct IdentificationCANInputView: View {
    var store: Store<IdentificationCANInput.State, IdentificationCANInput.Action>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.Identification.Can.Input.title,
                               message: L10n.Identification.Can.Input.body)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredCAN),
                                     maxDigits: Constants.CAN_DIGIT_COUNT,
                                     groupEvery: 3,
                                     showPIN: false,
                                     label: L10n.Identification.Can.Input.canInputLabel,
                                     backgroundColor: .neutral100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.Identification.Can.Input.continue,
                                                                          handler: { can in
                            viewStore.send(.done(can: can, request: viewStore.request, pushesToPINEntry: viewStore.pushesToPINEntry))
                        }))
                        .focused($pinEntryFocused)
                        .headingL()
                    }
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(false)
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                pinEntryFocused = true
            }
        }
        .interactiveDismissDisabled(true)
    }
}

struct IdentificationCANInput_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationCANInputView(store: .init(initialState: .init(request: .preview, pushesToPINEntry: true), reducer: IdentificationCANInput()))
        }
        .previewDevice("iPhone 12")
    }
}
