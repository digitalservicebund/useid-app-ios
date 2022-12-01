import SwiftUI
import ComposableArchitecture

struct IdentificationCANIncorrectInputState: Equatable {
    @BindableState var enteredCAN: String = ""
    let request: EIDAuthenticationRequest
    var pinCANCallback: PINCANCallback
    
    var doneButtonEnabled: Bool {
        return enteredCAN.count == Constants.CAN_DIGIT_COUNT
    }
}

enum IdentificationCANIncorrectInputAction: Equatable, BindableAction {
    case done(can: String)
    case triggerEnd
    case end(EIDAuthenticationRequest, PINCANCallback)
    case binding(BindingAction<IdentificationCANIncorrectInputState>)
}

var identificationCANIncorrectInputReducer = Reducer<IdentificationCANIncorrectInputState, IdentificationCANIncorrectInputAction, AppEnvironment>.init { state, action, _ in
    switch action {
    case .triggerEnd:
        return Effect(value: .end(state.request, state.pinCANCallback))
    default:
        return .none
    }
}.binding()

struct IdentificationCANIncorrectInput: View {
    var store: Store<IdentificationCANIncorrectInputState, IdentificationCANIncorrectInputAction>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        NavigationView {
                ScrollView {
                    WithViewStore(store) { viewStore in
                        VStack(alignment: .leading, spacing: 24) {
                            HeaderView(title: L10n.Identification.Can.IncorrectInput.title,
                                       message: L10n.Identification.Can.IncorrectInput.body)
                            VStack {
                                Spacer()
                                PINEntryView(pin: viewStore.binding(\.$enteredCAN),
                                             maxDigits: Constants.CAN_DIGIT_COUNT,
                                             groupEvery: 3,
                                             showPIN: false,
                                             label: L10n.Identification.Can.IncorrectInput.canInputLabel,
                                             backgroundColor: .neutral100,
                                             doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                                  title: L10n.Identification.Can.IncorrectInput.continue,
                                                                                  handler: { can in
                                    viewStore.send(.done(can: can))
                                }))
                                .focused($pinEntryFocused)
                                .font(.bundTitle)
                            }
                            
                            VStack(spacing: 3) {
                                Text(L10n.Identification.Can.IncorrectInput.Error.Incorrect.body)
                                    .font(.bundBodyBold)
                                    .foregroundColor(.red900)
                                Text(L10n.Identification.Can.IncorrectInput.Error.Incorrect.title)
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                    .multilineTextAlignment(.center)
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .frame(maxWidth: .infinity)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                }
                .navigationBarHidden(false)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            ViewStore(store).send(.triggerEnd)
                        } label: {
                            Text(verbatim: L10n.Identification.Can.IncorrectInput.back)
                                .foregroundColor(.blue800)
                                .font(.bundBody)
                        }
                    }
                }
                .focusOnAppear {
                    if !UIAccessibility.isVoiceOverRunning {
                        pinEntryFocused = true
                    }
                }
                .interactiveDismissDisabled(true, onAttemptToDismiss: {
                    ViewStore(store).send(.triggerEnd)
                })
            
        }
        
    }
}

struct IdentificationCANIncorrectInput_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationCANIncorrectInput(store: .init(initialState: .init(request: .preview, pinCANCallback: PINCANCallback(id: UUID(), callback: { _, _ in })),
                                                         reducer: identificationCANIncorrectInputReducer,
                                                         environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
