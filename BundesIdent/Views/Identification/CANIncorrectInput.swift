import ComposableArchitecture
import SwiftUI

struct CANIncorrectInput: ReducerProtocol {
    struct State: Equatable {
        @BindingState var enteredCAN: String = ""
        
        var doneButtonEnabled: Bool {
            enteredCAN.count == Constants.CAN_DIGIT_COUNT
        }
    }

    enum Action: Equatable, BindableAction {
        case done(can: String)
        case end
        case binding(BindingAction<CANIncorrectInput.State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
    }
}

struct CANIncorrectInputView: View {
    var store: Store<CANIncorrectInput.State, CANIncorrectInput.Action>
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
                    BackButton {
                        ViewStore(store).send(.end)
                    }
                }
            }
            .focusOnAppear {
                if !UIAccessibility.isVoiceOverRunning {
                    pinEntryFocused = true
                }
            }
            .interactiveDismissDisabled(true, onAttemptToDismiss: {
                ViewStore(store).send(.end)
            })
        }
    }
}

#if DEBUG

struct CANIncorrectInput_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CANIncorrectInputView(store: .init(initialState: .init(),
                                               reducer: CANIncorrectInput()))
        }
        .previewDevice("iPhone 12")
    }
}

#endif
