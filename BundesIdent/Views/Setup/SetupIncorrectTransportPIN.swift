import SwiftUI
import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

struct SetupIncorrectTransportPIN: ReducerProtocol {
    struct State: Equatable {
        
#if DEBUG || PREVIEW
        var maxDigits: Int = 5
#else
        var maxDigits: Int { 5 }
#endif
        
        @BindingState var enteredPIN: String = ""
        @BindingState var focusTextField: Bool = true
        @BindingState var alert: AlertState<SetupIncorrectTransportPIN.Action>?
    }
    
    enum Action: BindableAction, Equatable {
        case done(transportPIN: String)
        case swipeToDismiss
        case end
        case confirmEnd
        case dismissAlert
        case binding(BindingAction<SetupIncorrectTransportPIN.State>)
        
#if DEBUG || PREVIEW
        case toggleDigitCount
#endif
    }

    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .swipeToDismiss,
                 .end:
                state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                                         message: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                                         primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm),
                                                                     action: .send(.confirmEnd)),
                                         secondaryButton: .cancel(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
                return .none
#if DEBUG || PREVIEW
            case .toggleDigitCount:
                if state.maxDigits == 5 {
                    state.maxDigits = 6
                } else {
                    state.maxDigits = 5
                }
                return .none
#endif
            default:
                return .none
            }
        }
    }
}

struct SetupIncorrectTransportPINView: View {
    
    let store: Store<SetupIncorrectTransportPIN.State, SetupIncorrectTransportPIN.Action>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        WithViewStore(store) { viewStore in
                            Text(L10n.FirstTimeUser.IncorrectTransportPIN.title)
                                .headingXL()
                            Text(L10n.FirstTimeUser.IncorrectTransportPIN.body)
                                .bodyLRegular()
                            ZStack {
                                Image(decorative: "Transport-PIN")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                             maxDigits: viewStore.maxDigits,
                                             label: L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel,
                                             doneConfiguration: DoneConfiguration(enabled: viewStore.enteredPIN.count == viewStore.maxDigits,
                                                                                  title: L10n.FirstTimeUser.IncorrectTransportPIN.continue,
                                                                                  handler: { pin in
                                                                                      viewStore.send(.done(transportPIN: pin))
                                                                                  }))
                                                                                  .focused($pinEntryFocused)
                                                                                  .headingL()
                                                                                  .background(Color.white.cornerRadius(10))
                                                                                  .padding(40)
                            }
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button(L10n.General.cancel) {
                                        viewStore.send(.end)
                                    }
                                    .bodyLRegular(color: .accentColor)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
#if DEBUG || PREVIEW
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        WithViewStore(store) { viewStore in
                            Button("\(Image(systemName: "arrow.left.and.right")) \(viewStore.maxDigits == 5 ? "6" : "5")") {
                                viewStore.send(.toggleDigitCount)
                            }
                        }
                    }
                }
#endif
                .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
        }
        .interactiveDismissDisabled {
            ViewStore(store.stateless).send(.swipeToDismiss)
        }
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                pinEntryFocused = true
            }
        }
    }
}

struct SetupIncorrectTransportPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupIncorrectTransportPINView(store: Store(initialState: .init(),
                                                        reducer: SetupIncorrectTransportPIN()))
        }
        NavigationView {
            SetupIncorrectTransportPINView(store: Store(initialState: .init(enteredPIN: "12345"),
                                                        reducer: SetupIncorrectTransportPIN()))
        }
    }
}
