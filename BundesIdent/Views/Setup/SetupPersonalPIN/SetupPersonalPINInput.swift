import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPINInput: ReducerProtocol {
    struct State: Equatable {
        @BindingState var enteredPIN = ""
        var doneButtonEnabled: Bool {
            enteredPIN.count == Constants.PERSONAL_PIN_DIGIT_COUNT
        }
    }
    
    enum Action: BindableAction, Equatable {
        case done(pin: String)
        case onAppear
        case binding(BindingAction<State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.enteredPIN = ""
                return .none
            default:
                return .none
            }
        }
    }
}

struct SetupPersonalPINInputView: View {
    var store: Store<SetupPersonalPINInput.State, SetupPersonalPINInput.Action>
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
                                     backgroundColor: .neutral100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.FirstTimeUser.PersonalPIN.continue,
                                                                          handler: { _ in
                                                                              viewStore.send(.done(pin: viewStore.enteredPIN))
                                                                          }))
                                                                          .focused($pinEntryFocused)
                                                                          .headingL()
                    }
                    Spacer()
                }
                .focusOnAppear {
                    if !UIAccessibility.isVoiceOverRunning {
                        pinEntryFocused = true
                    }
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
            SetupPersonalPINInputView(store: Store(initialState: SetupPersonalPINInput.State(enteredPIN: "12345"),
                                                   reducer: SetupPersonalPINInput()))
        }
        .previewDevice("iPhone 12")
    }
}
