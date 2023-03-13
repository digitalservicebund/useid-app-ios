import SwiftUI
import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

struct SetupTransportPIN: ReducerProtocol {
    struct State: Equatable {
        @BindingState var enteredPIN = ""
        var digits = 5
        var attempts: Int?
    }
    
    enum Action: BindableAction, Equatable {
        case done(transportPIN: String)
        case binding(BindingAction<SetupTransportPIN.State>)
#if DEBUG || PREVIEW
        case toggleDigits
#endif
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
#if DEBUG || PREVIEW
            case .toggleDigits:
                state.digits = 11 - state.digits
                return .none
#endif
            default:
                return .none
            }
        }
    }
}

struct SetupTransportPINView: View {
    let store: Store<SetupTransportPIN.State, SetupTransportPIN.Action>
    @FocusState private var pinEntryFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(L10n.FirstTimeUser.TransportPIN.title)
                    .headingXL()
                Text(L10n.FirstTimeUser.TransportPIN.body)
                    .bodyLRegular()
                ZStack {
                    Image(decorative: Asset.transportPIN)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    
                    WithViewStore(store) { viewStore in
                        PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                     maxDigits: viewStore.digits,
                                     label: L10n.FirstTimeUser.TransportPIN.textFieldLabel,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.enteredPIN.count == viewStore.digits,
                                                                          title: L10n.FirstTimeUser.TransportPIN.continue,
                                                                          handler: { pin in
                                                                              viewStore.send(.done(transportPIN: pin))
                                                                          }))
                                                                          .focused($pinEntryFocused)
                                                                          .headingL()
                                                                          .background(Color.white.cornerRadius(10))
                                                                          .padding(40)
                    }
                }
                IfLetStore(store.scope(state: \.attempts).actionless) {
                    WithViewStore($0) { remainingAttempts in
                        VStack(spacing: 24) {
                            VStack {
                                Text(L10n.FirstTimeUser.IncorrectTransportPIN.remainingAttemptsLld(remainingAttempts.state))
                                    .bodyLRegular()
                                    .multilineTextAlignment(.center)
                                    .lineLimit(nil)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
        }
        .focusOnAppear {
            if !UIAccessibility.isVoiceOverRunning {
                pinEntryFocused = true
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
#if DEBUG || PREVIEW
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    WithViewStore(store) { viewStore in
                        Button("\(Image(systemName: "arrow.left.and.right")) \(viewStore.digits == 5 ? "6" : "5")") {
                            viewStore.send(.toggleDigits)
                        }
                    }
                }
            }
#endif
    }
}

struct SetupTransportPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupTransportPINView(store: Store(initialState: .init(),
                                               reducer: SetupTransportPIN()))
        }
        .previewDisplayName("w/o pin")
        NavigationView {
            SetupTransportPINView(store: Store(initialState: .init(enteredPIN: "12345"),
                                               reducer: SetupTransportPIN()))
        }
        .previewDisplayName("w/ pin")
        NavigationView {
            SetupTransportPINView(store: Store(initialState: .init(enteredPIN: "12345",
                                                                   attempts: 1),
                                               reducer: SetupTransportPIN()))
        }
        .previewDisplayName("1 attempts")
    }
}
