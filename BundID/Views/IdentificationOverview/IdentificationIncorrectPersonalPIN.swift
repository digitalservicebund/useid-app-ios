import SwiftUI
import Combine
import ComposableArchitecture

enum PersonalPINError: Equatable {
    case incorrect
}

struct IdentificationIncorrectPersonalPINState: Equatable {
    @BindableState var enteredPIN: String = ""
    var error: PersonalPINError?
    var remainingAttempts: Int
    @BindableState var alert: AlertState<IdentificationIncorrectPersonalPINAction>?
    
    var doneButtonEnabled: Bool {
        return enteredPIN.count == 6
    }
    
    mutating func handlePINChange(_ enteredPIN: String) -> Effect<IdentificationIncorrectPersonalPINAction, Never> {
        if !enteredPIN.isEmpty {
            withAnimation {
                error = nil
            }
        }
        
        return .none
    }
}

enum IdentificationIncorrectPersonalPINAction: BindableAction, Equatable {
    case onAppear
    case done(pin: String)
    case end
    case confirmEnd
    case afterConfirmEnd
    case dismissAlert
    case binding(BindingAction<IdentificationIncorrectPersonalPINState>)
}

let identificationIncorrectPersonalPINReducer = Reducer<IdentificationIncorrectPersonalPINState, IdentificationIncorrectPersonalPINAction, AppEnvironment> { state, action, _ in
    switch action {
    case .binding(\.$enteredPIN):
        return state.handlePINChange(state.enteredPIN)
    case .end:
        state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.title),
                                 message: TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.message),
                                 primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.End.confirm),
                                                             action: .send(.confirmEnd)),
                                 secondaryButton: .cancel(TextState(verbatim: L10n.General.cancel)))
        return .none
    case .dismissAlert:
        state.alert = nil
        return .none
    default:
        return .none
    }
}.binding()

struct IdentificationIncorrectPersonalPIN: View {
    
    var store: Store<IdentificationIncorrectPersonalPINState, IdentificationIncorrectPersonalPINAction>
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(L10n.Identification.PersonalPIN.title)
                            .font(.bundLargeTitle)
                            .foregroundColor(.blackish)
                        VStack {
                            Spacer()
                            WithViewStore(store) { viewStore in
                                PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                             maxDigits: 6,
                                             groupEvery: 3,
                                             showPIN: false,
                                             label: L10n.Identification.PersonalPIN.textFieldLabel,
                                             shouldBeFocused: .constant(true),
                                             doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                                  title: L10n.Identification.PersonalPIN.continue,
                                                                                  handler: { pin in
                                    viewStore.send(.done(pin: pin))
                                }))
                                .font(.bundTitle)
                            }
                        }
                        
                        VStack {
                            WithViewStore(store) { viewStore in
                                if case .incorrect = viewStore.error {
                                    VStack(spacing: 3) {
                                        Text(L10n.Identification.PersonalPIN.Error.Incorrect.title)
                                            .font(.bundBodyBold)
                                            .foregroundColor(.red900)
                                        Text(L10n.Identification.PersonalPIN.Error.Incorrect.body)
                                            .font(.bundBody)
                                            .foregroundColor(.blackish)
                                            .multilineTextAlignment(.center)
                                    }
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                                Text(L10n.Identification.PersonalPIN.Error.Incorrect.remainingAttemptsLld(viewStore.remainingAttempts))
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                    .multilineTextAlignment(.center)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        Spacer()
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                ViewStore(store.stateless).send(.end)
                            } label: {
                                Text(verbatim: L10n.FirstTimeUser.IncorrectTransportPIN.end)
                            }
                        }
                    }
                    .onAppear {
                        ViewStore(store.stateless).send(.onAppear)
                    }
                }
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
        }
        .interactiveDismissDisabled {
            ViewStore(store.stateless).send(.end)
        }
    }
}

struct IdentificationIncorrectPersonalPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationIncorrectPersonalPIN(store: Store(initialState: IdentificationIncorrectPersonalPINState(enteredPIN: "", error: .incorrect, remainingAttempts: 2),
                                                   reducer: .empty,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
        NavigationView {
            IdentificationIncorrectPersonalPIN(store: Store(initialState: IdentificationIncorrectPersonalPINState(enteredPIN: "12",
                                                                                                error: nil,
                                                                                               remainingAttempts: 2),
                                                   reducer: .empty,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
