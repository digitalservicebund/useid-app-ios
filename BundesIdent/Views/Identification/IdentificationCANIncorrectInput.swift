import SwiftUI
import ComposableArchitecture

struct IdentificationCANIncorrectInput: ReducerProtocol {
    struct State: Equatable {
        @BindableState var enteredCAN: String = ""
        let request: EIDAuthenticationRequest
        
        var doneButtonEnabled: Bool {
            enteredCAN.count == Constants.CAN_DIGIT_COUNT
        }
    }

    enum Action: Equatable, BindableAction {
        case done(can: String)
        case triggerEnd
        case end(EIDAuthenticationRequest)
        case binding(BindingAction<IdentificationCANIncorrectInput.State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .triggerEnd:
                return Effect(value: .end(state.request))
            default:
                return .none
            }
        }
    }
}

struct IdentificationCANIncorrectInputView: View {
    var store: Store<IdentificationCANIncorrectInput.State, IdentificationCANIncorrectInput.Action>
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
                                         showPIN: true,
                                         label: L10n.Identification.Can.IncorrectInput.canInputLabel,
                                         backgroundColor: .neutral100,
                                         doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                              title: L10n.Identification.Can.IncorrectInput.continue,
                                                                              handler: { can in
                                                                                  viewStore.send(.done(can: can))
                                                                              }))
                                                                              .focused($pinEntryFocused)
                                                                              .headingL()
                        }
                            
                        VStack(spacing: 3) {
                            Text(L10n.Identification.Can.IncorrectInput.Error.Incorrect.body)
                                .bodyLBold(color: .red900)
                            Text(L10n.Identification.Can.IncorrectInput.Error.Incorrect.title)
                                .bodyLRegular()
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
                    Button(L10n.Identification.Can.IncorrectInput.back) {
                        ViewStore(store).send(.triggerEnd)
                    }
                    .bodyLRegular(color: .accentColor)
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
            IdentificationCANIncorrectInputView(store: .init(initialState: .init(request: .preview),
                                                             reducer: IdentificationCANIncorrectInput()))
        }
        .previewDevice("iPhone 12")
    }
}
