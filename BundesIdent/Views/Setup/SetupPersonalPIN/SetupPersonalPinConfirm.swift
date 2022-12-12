import SwiftUI
import Combine
import ComposableArchitecture
import Analytics

struct SetupPersonalPINConfirm: ReducerProtocol {
    @Dependency(\.analytics) var analytics: AnalyticsClient
    
    struct State: Equatable {
        var enteredPIN1: String
        @BindableState var enteredPIN2 = ""
        @BindableState var alert: AlertState<SetupPersonalPINConfirm.Action>?
        
        var doneButtonEnabled: Bool {
            enteredPIN2.count == Constants.PERSONAL_PIN_DIGIT_COUNT
        }
    }
    
    enum Action: BindableAction, Equatable {
        case done(pin: String)
        case mismatchError
        case confirmMismatch
        case dismissAlert
        case checkPINs
        case binding(BindingAction<SetupPersonalPINConfirm.State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .mismatchError:
                state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title),
                                         message: nil,
                                         buttons: [.default(TextState(L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.retry), action: .send(.confirmMismatch))])
                return .none
            case .checkPINs:
                guard state.enteredPIN2.count == Constants.PERSONAL_PIN_DIGIT_COUNT else { return .none }
                guard state.enteredPIN1 == state.enteredPIN2 else {
                    return .concatenate(
                        .trackEvent(category: "firstTimeUser",
                                    action: "errorShown",
                                    name: "personalPINMismatch",
                                    analytics: analytics),
                        Effect(value: .mismatchError)
                    )
                }
                return Effect(value: .done(pin: state.enteredPIN1))
            default:
                return .none
            }
        }
    }
}

struct SetupPersonalPINConfirmView: View {
    var store: Store<SetupPersonalPINConfirm.State, SetupPersonalPINConfirm.Action>
    @FocusState private var pinEntryFocused: Bool
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.FirstTimeUser.PersonalPIN.Confirmation.title,
                               message: L10n.FirstTimeUser.PersonalPIN.Confirmation.body)
                    VStack {
                        Spacer()
                        VStack {
                            PINEntryView(pin: viewStore.binding(\.$enteredPIN2),
                                         maxDigits: Constants.PERSONAL_PIN_DIGIT_COUNT,
                                         groupEvery: 3,
                                         showPIN: false,
                                         label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second,
                                         backgroundColor: .neutral100,
                                         doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                              title: L10n.FirstTimeUser.PersonalPIN.continue,
                                                                              handler: { _ in
                                                                                  viewStore.send(.checkPINs)
                                                                              }))
                                                                              .focused($pinEntryFocused)
                                                                              .headingL()
                            Spacer()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    Spacer()
                }
                .focusOnAppear {
                    if !UIAccessibility.isVoiceOverRunning {
                        pinEntryFocused = true
                    }
                }
            }
            .padding(.horizontal)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
        .interactiveDismissDisabled()
    }
}

struct SetupPersonalPINConfirm_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupPersonalPINConfirmView(store: Store(initialState: SetupPersonalPINConfirm.State(enteredPIN1: "12345"),
                                                     reducer: SetupPersonalPINConfirm()))
        }
        .previewDevice("iPhone 12")
    }
}
