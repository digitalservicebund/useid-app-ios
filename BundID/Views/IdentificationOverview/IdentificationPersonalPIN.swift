import SwiftUI
import Combine
import ComposableArchitecture

enum PersonalPINError: Equatable {
    case incorrect
}

struct IdentificationPersonalPINState: Equatable {
    @BindableState var enteredPIN: String = ""
    var error: PersonalPINError?
    var remainingAttempts: Int?
    
    var doneButtonEnabled: Bool {
        return enteredPIN.count == 6
    }
    
    mutating func handlePINChange(_ enteredPIN: String) -> Effect<IdentificationPersonalPINAction, Never> {
        if !enteredPIN.isEmpty {
            withAnimation {
                error = nil
            }
        }
        
        return .none
    }
}

enum IdentificationPersonalPINAction: BindableAction, Equatable {
    case onAppear
    case done(pin: String)
    case reset
    case binding(BindingAction<IdentificationPersonalPINState>)
}

let identificationPersonalPINReducer = Reducer<IdentificationPersonalPINState, IdentificationPersonalPINAction, AppEnvironment> { state, action, _ in
    switch action {
    case .onAppear:
        return .none
    case .binding(\.$enteredPIN):
        return state.handlePINChange(state.enteredPIN)
    case .binding:
        return .none
    case .reset:
        state.error = nil
        state.enteredPIN = ""
        return .none
    case .done:
        return .none
    }
}.binding()

struct IdentificationPersonalPIN: View {
    
    var store: Store<IdentificationPersonalPINState, IdentificationPersonalPINAction>
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.Identification.PersonalPIN.title)
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                    VStack {
                        Spacer()
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
                    
                    VStack {
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
                        if let remainingAttempts = viewStore.remainingAttempts {
                            Text(L10n.Identification.PersonalPIN.Error.Incorrect.remainingAttemptsLld(remainingAttempts))
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
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct IdentificationPersonalPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationPersonalPIN(store: Store(initialState: IdentificationPersonalPINState(enteredPIN: "12345"),
                                                   reducer: .empty,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
        NavigationView {
            IdentificationPersonalPIN(store: Store(initialState: IdentificationPersonalPINState(enteredPIN: "",
                                                                                                error: .incorrect,
                                                                                               remainingAttempts: 2),
                                                   reducer: .empty,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
        NavigationView {
            IdentificationPersonalPIN(store: Store(initialState: IdentificationPersonalPINState(enteredPIN: "1",
                                                                                                error: nil,
                                                                                               remainingAttempts: 2),
                                                   reducer: .empty,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
