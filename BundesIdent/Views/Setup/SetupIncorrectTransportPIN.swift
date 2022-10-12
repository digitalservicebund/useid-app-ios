import SwiftUI
import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

struct SetupIncorrectTransportPINState: Equatable {
    var remainingAttempts: Int
    
#if DEBUG && !PREVIEW
    var maxDigits: Int = 5
#else
    var maxDigits: Int { 5 }
#endif
    
    @BindableState var enteredPIN: String = ""
    @BindableState var focusTextField: Bool = true
    @BindableState var alert: AlertState<SetupIncorrectTransportPINAction>?
}

enum SetupIncorrectTransportPINAction: BindableAction, Equatable {
    case done(transportPIN: String)
    case end
    case confirmEnd
    case dismissAlert
    case binding(BindingAction<SetupIncorrectTransportPINState>)
    
#if DEBUG && !PREVIEW
    case toggleDigitCount
#endif
}

let setupIncorrectTransportPINReducer = Reducer<SetupIncorrectTransportPINState, SetupIncorrectTransportPINAction, AppEnvironment> { state, action, _ in
    switch action {
    case .end:
        state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                                 message: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                                 primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm),
                                                             action: .send(.confirmEnd)),
                                 secondaryButton: .cancel(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
        return .none
#if DEBUG && !PREVIEW
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
}.binding()

struct SetupIncorrectTransportPIN: View {
    
    let store: Store<SetupIncorrectTransportPINState, SetupIncorrectTransportPINAction>
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        WithViewStore(store) { viewStore in
                            Text(L10n.FirstTimeUser.IncorrectTransportPIN.title)
                                .font(.bundLargeTitle)
                                .foregroundColor(.blackish)
                            Text(L10n.FirstTimeUser.IncorrectTransportPIN.body)
                                .font(.bundBody)
                                .foregroundColor(.blackish)
                            ZStack {
                                Image(decorative: "Transport-PIN")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                             maxDigits: viewStore.maxDigits,
                                             label: L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel,
                                             shouldBeFocused: viewStore.binding(\.$focusTextField),
                                             doneConfiguration: DoneConfiguration(enabled: viewStore.enteredPIN.count == viewStore.maxDigits,
                                                                                  title: L10n.FirstTimeUser.IncorrectTransportPIN.continue,
                                                                                  handler: { pin in
                                    viewStore.send(.done(transportPIN: pin))
                                }))
                                .font(.bundTitle)
                                .background(Color.white.cornerRadius(10))
                                .padding(40)
                            }
                            VStack(spacing: 24) {
                                VStack {
                                    Text(L10n.FirstTimeUser.IncorrectTransportPIN.remainingAttemptsLld(viewStore.remainingAttempts))
                                        .font(.bundBody)
                                        .foregroundColor(.blackish)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button {
                                        viewStore.send(.end)
                                    } label: {
                                        Text(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.end)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
#if DEBUG && !PREVIEW
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
            ViewStore(store.stateless).send(.end)
        }
    }
}

struct SetupIncorrectTransportPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupIncorrectTransportPIN(store: Store(initialState: .init(remainingAttempts: 2),
                                                    reducer: .empty,
                                                    environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            SetupIncorrectTransportPIN(store: Store(initialState: .init(remainingAttempts: 2, enteredPIN: "12345"),
                                                    reducer: .empty,
                                                    environment: AppEnvironment.preview))
        }
        NavigationView {
            SetupIncorrectTransportPIN(store: Store(initialState: .init(remainingAttempts: 1),
                                                    reducer: .empty,
                                                    environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
