import SwiftUI
import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

struct SetupIncorrectTransportPINState: Equatable {
    var remainingAttempts: Int
    
    @BindableState var enteredPIN: String = ""
    @BindableState var focusTextField: Bool = true
    @BindableState var alert: AlertState<SetupIncorrectTransportPINAction>?
}

enum SetupIncorrectTransportPINAction: BindableAction, Equatable {
    case done(transportPIN: String)
    case end
    case confirmEnd
    case afterConfirmEnd
    case dismissAlert
    case binding(BindingAction<SetupIncorrectTransportPINState>)
}

let setupIncorrectTransportPINReducer = Reducer<SetupIncorrectTransportPINState, SetupIncorrectTransportPINAction, AppEnvironment> { state, action, _ in
    switch action {
    case .end:
        state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.title),
                                 message: TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.message),
                                 primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.confirm),
                                                             action: .send(.confirmEnd)),
                                 secondaryButton: .cancel(TextState(verbatim: L10n.General.cancel)))
        return .none
    default:
        return .none
    }
}.binding()

struct SetupIncorrectTransportPIN: View {
    
    var store: Store<SetupIncorrectTransportPINState, SetupIncorrectTransportPINAction>
    var viewStore: ViewStore<SetupIncorrectTransportPINState, SetupIncorrectTransportPINAction>
    
    init(store: Store<SetupIncorrectTransportPINState, SetupIncorrectTransportPINAction>) {
        self.store = store
        self.viewStore = ViewStore(store)
    }
    
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
                                             maxDigits: 5,
                                             label: L10n.FirstTimeUser.IncorrectTransportPIN.textFieldLabel,
                                             shouldBeFocused: viewStore.binding(\.$focusTextField),
                                             doneConfiguration: DoneConfiguration(enabled: viewStore.enteredPIN.count == 5,
                                                                                  title: L10n.FirstTimeUser.IncorrectTransportPIN.continue,
                                                                                  handler: { pin in
                                    viewStore.send(.done(transportPIN: pin))
                                }))
                                .font(.bundTitle)
                                .background(
                                    Color.white.cornerRadius(10)
                                )
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
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
        }
        .interactiveDismissDisabled {
            viewStore.send(.end)
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
