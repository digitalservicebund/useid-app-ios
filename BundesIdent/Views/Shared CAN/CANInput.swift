import SwiftUI
import ComposableArchitecture

struct CANInput: ReducerProtocol {
    struct State: Equatable {
        @BindingState var enteredCAN: String = ""
        var pushesToPINEntry: Bool
        var doneButtonEnabled: Bool {
            enteredCAN.count == Constants.CAN_DIGIT_COUNT
        }
    }
    
    enum Action: Equatable, BindableAction {
        case done(can: String, pushesToPINEntry: Bool)
        case binding(BindingAction<State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
    }
}

struct CANInputView: View {
    var store: StoreOf<CANInput>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.Identification.Can.Input.title,
                               message: L10n.Identification.Can.Input.body)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredCAN),
                                     maxDigits: Constants.CAN_DIGIT_COUNT,
                                     groupEvery: 3,
                                     showPIN: true,
                                     label: L10n.Identification.Can.Input.canInputLabel,
                                     backgroundColor: .neutral100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.Identification.Can.Input.continue,
                                                                          handler: { can in
                                                                              viewStore.send(.done(can: can, pushesToPINEntry: viewStore.pushesToPINEntry))
                                                                          }))
                                                                          .focused($pinEntryFocused)
                                                                          .headingL()
                    }
                    Spacer()
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
        .interactiveDismissDisabled(true)
    }
}

#if DEBUG

struct CANInput_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CANInputView(store: .init(initialState: .init(pushesToPINEntry: true), reducer: CANInput()))
        }
        .previewDevice("iPhone 12")
    }
}

#endif
