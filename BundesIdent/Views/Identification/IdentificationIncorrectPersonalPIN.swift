import SwiftUI
import Combine
import ComposableArchitecture

enum PersonalPINError: Equatable {
    case incorrect
}

struct IdentificationIncorrectPersonalPIN: ReducerProtocol {
    struct State: Equatable {
        @BindableState var enteredPIN: String = ""
        var error: PersonalPINError?
        var remainingAttempts: Int
        @BindableState var alert: AlertState<IdentificationIncorrectPersonalPIN.Action>?
        
        var doneButtonEnabled: Bool {
            enteredPIN.count == Constants.PERSONAL_PIN_DIGIT_COUNT
        }
        
        mutating func handlePINChange(_ enteredPIN: String) -> Effect<IdentificationIncorrectPersonalPIN.Action, Never> {
            if !enteredPIN.isEmpty {
                withAnimation {
                    error = nil
                }
            }
            
            return .none
        }
    }
    
    enum Action: BindableAction, Equatable {
        case onAppear
        case done(pin: String)
        case end
        case confirmEnd
        case dismissAlert
        case binding(BindingAction<IdentificationIncorrectPersonalPIN.State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .binding(\.$enteredPIN):
                return state.handlePINChange(state.enteredPIN)
            case .end:
                state.alert = AlertState(title: TextState(verbatim: L10n.Identification.ConfirmEnd.title),
                                         message: TextState(verbatim: L10n.Identification.ConfirmEnd.message),
                                         primaryButton: .destructive(TextState(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                                                     action: .send(.confirmEnd)),
                                         secondaryButton: .cancel(TextState(verbatim: L10n.Identification.ConfirmEnd.deny)))
                return .none
            case .dismissAlert:
                state.alert = nil
                return .none
            default:
                return .none
            }
        }
    }
}

struct IdentificationIncorrectPersonalPINView: View {
    
    var store: Store<IdentificationIncorrectPersonalPIN.State, IdentificationIncorrectPersonalPIN.Action>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        NavigationView {
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
                                                                                      viewStore.send(.done(pin: pin))
                                                                                  }))
                                                                                  .focused($pinEntryFocused)
                                                                                  .headingL()
                            }
                        }
                        
                        VStack {
                            WithViewStore(store) { viewStore in
                                if case .incorrect = viewStore.error {
                                    VStack(spacing: 3) {
                                        Text(L10n.Identification.PersonalPIN.Error.Incorrect.title)
                                            .bodyLBold(color: .red900)
                                        Text(L10n.Identification.PersonalPIN.Error.Incorrect.body)
                                            .bodyLRegular()
                                            .multilineTextAlignment(.center)
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(L10n.General.cancel) {
                                ViewStore(store.stateless).send(.end)
                            }
                            .bodyLRegular(color: .accentColor)
                        }
                    }
                    .onAppear {
                        ViewStore(store.stateless).send(.onAppear)
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
        }
        .interactiveDismissDisabled {
            ViewStore(store.stateless).send(.end)
        }
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                pinEntryFocused = true
            }
        }
    }
}

struct IdentificationIncorrectPersonalPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationIncorrectPersonalPINView(store: Store(initialState: IdentificationIncorrectPersonalPIN.State(enteredPIN: "",
                                                                                                                       error: .incorrect,
                                                                                                                       remainingAttempts: 2),
                                                                reducer: IdentificationIncorrectPersonalPIN()))
        }
        .previewDevice("iPhone 12")
        NavigationView {
            IdentificationIncorrectPersonalPINView(store: Store(initialState: IdentificationIncorrectPersonalPIN.State(enteredPIN: "12",
                                                                                                                       error: nil,
                                                                                                                       remainingAttempts: 2),
                                                                reducer: IdentificationIncorrectPersonalPIN()))
        }
        .previewDevice("iPhone 12")
    }
}
