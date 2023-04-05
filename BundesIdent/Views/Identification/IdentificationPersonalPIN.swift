import SwiftUI
import Combine
import ComposableArchitecture

struct IdentificationPersonalPIN: ReducerProtocol {
    struct State: Equatable {
        var authenticationInformation: AuthenticationInformation
        @BindingState var enteredPIN: String = ""
        
        var doneButtonEnabled: Bool {
            enteredPIN.count == Constants.PERSONAL_PIN_DIGIT_COUNT
        }
    }

    enum Action: BindableAction, Equatable {
        case onAppear
        case done(authenticationInformation: AuthenticationInformation, pin: String)
        case binding(BindingAction<IdentificationPersonalPIN.State>)
    }

    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
    }
}

struct IdentificationPersonalPINView: View {
    
    var store: Store<IdentificationPersonalPIN.State, IdentificationPersonalPIN.Action>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.Identification.PersonalPIN.title)
                        .headingXL()
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                     maxDigits: Constants.PERSONAL_PIN_DIGIT_COUNT,
                                     groupEvery: 3,
                                     showPIN: false,
                                     label: L10n.Identification.PersonalPIN.textFieldLabel,
                                     backgroundColor: .neutral100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.Identification.PersonalPIN.continue,
                                                                          handler: { pin in
                                                                              viewStore.send(.done(authenticationInformation: viewStore.authenticationInformation, pin: pin))
                                                                          }))
                                                                          .focused($pinEntryFocused)
                                                                          .headingL()
                    }
                    Spacer()
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(false)
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                pinEntryFocused = true
            }
        }
    }
}

#if DEBUG

struct IdentificationPersonalPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationPersonalPINView(store: Store(initialState: IdentificationPersonalPIN.State(authenticationInformation: .preview, enteredPIN: "12345"),
                                                       reducer: IdentificationPersonalPIN()))
        }
        .previewDevice("iPhone 12")
        NavigationView {
            IdentificationPersonalPINView(store: Store(initialState: IdentificationPersonalPIN.State(authenticationInformation: .preview),
                                                       reducer: IdentificationPersonalPIN()))
        }
        .previewDevice("iPhone 12")
    }
}

#endif
