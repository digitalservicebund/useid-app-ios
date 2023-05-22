import ComposableArchitecture
import SwiftUI

enum Input {
    case transportPIN
    case pin
    case can
    case puk
    
    var digits: Int {
        switch self {
        case .transportPIN: return Constants.TRANSPORT_PIN_DIGIT_COUNT
        case .pin: return Constants.PERSONAL_PIN_DIGIT_COUNT
        case .can: return Constants.CAN_DIGIT_COUNT
        case .puk: return Constants.PUK_DIGIT_COUNT
        }
    }
    
    var groups: Int? {
        switch self {
        case .transportPIN: return nil
        case .pin: return 3
        case .can: return 3
        case .puk: return nil
        }
    }
    
    var showDigits: Bool {
        switch self {
        case .transportPIN: return false
        case .pin: return false
        case .can: return true
        case .puk: return true
        }
    }
    
    var label: String {
        switch self {
        case .transportPIN: return L10n.Input.TransportPIN.label
        case .pin: return L10n.Input.Pin.label
        case .can: return L10n.Input.Can.label
        case .puk: return L10n.Input.Puk.label
        }
    }
}

struct InputError: Equatable {
    var title: String
    var body: String
}

struct InputFeature: ReducerProtocol {
    
    struct State: Equatable {
        @BindingState var digits = ""
        var inputError: InputError?
    }
    
    enum Action: BindableAction, Equatable {
        case done(digits: String)
        case onAppear
        case binding(BindingAction<State>)
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.digits = ""
                return .none
            default:
                return .none
            }
        }
    }
}

struct InputView: View {
    
    let input: Input
    let title: String
    let message: String?
    
    var store: StoreOf<InputFeature>
    @FocusState private var inputFocused: Bool
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: title,
                               message: message)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$digits),
                                     maxDigits: input.digits,
                                     groupEvery: input.groups,
                                     showPIN: input.showDigits,
                                     label: input.label,
                                     backgroundColor: .neutral100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.digits.count == input.digits,
                                                                          title: L10n.Identification.Can.Input.continue,
                                                                          handler: { _ in
                                                                              viewStore.send(.done(digits: viewStore.digits))
                                                                          }))
                                                                          .focused($inputFocused)
                                                                          .headingL()
                    }
                    
                    if let inputError = viewStore.inputError {
                        VStack(spacing: 3) {
                            Text(inputError.title)
                                .bodyLBold(color: .red900)
                            Text(inputError.body)
                                .bodyLRegular()
                                .multilineTextAlignment(.center)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .frame(maxWidth: .infinity)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .navigationBarHidden(false)
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                inputFocused = true
            }
        }
        .interactiveDismissDisabled(true)
    }
}

#if DEBUG

struct PUKInput_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InputView(
                input: .puk,
                title: L10n.Input.Puk.title,
                message: L10n.Input.Puk.body,
                store: .init(initialState: .init(), reducer: InputFeature())
            )
        }
        .previewDevice("iPhone 12")
    }
}

#endif
