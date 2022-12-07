import SwiftUI
import ComposableArchitecture

struct IdentificationCANInputState: Equatable {
    @BindableState var enteredCAN: String = ""
    let request: EIDAuthenticationRequest
    var pushesToPINEntry: Bool
    var doneButtonEnabled: Bool {
        return enteredCAN.count == Constants.CAN_DIGIT_COUNT
    }
}

enum IdentificationCANInputAction: Equatable, BindableAction {
    case done(can: String, request: EIDAuthenticationRequest, pushesToPINEntry: Bool)
    case binding(BindingAction<IdentificationCANInputState>)
}

var identificationCANInputReducer = Reducer<IdentificationCANInputState, IdentificationCANInputAction, AppEnvironment>.init { _, action, _ in
    switch action {
    default:
        return .none
    }
}.binding()

struct IdentificationCANInput: View {
    var store: Store<IdentificationCANInputState, IdentificationCANInputAction>
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
            IdentificationCANInput(store: .init(initialState: .init(request: .preview, pushesToPINEntry: true),
                                                reducer: identificationCANInputReducer,
                                                environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
