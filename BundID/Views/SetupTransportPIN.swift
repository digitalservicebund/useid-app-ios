import SwiftUI
import ComposableArchitecture
import FlowStacks
import TCACoordinators
import IdentifiedCollections

struct SetupTransportPINState: Equatable {
    @BindableState var enteredPIN: String = ""
    var remainingAttempts: Int = 3
    var previouslyUnsuccessful: Bool = false
    @BindableState var isFinished: Bool = false
    @BindableState var focusTextField: Bool = true
}

enum SetupTransportPINAction: BindableAction, Equatable {
    case done
    case binding(BindingAction<SetupTransportPINState>)
}

let setupTransportPINReducer = Reducer<SetupTransportPINState, SetupTransportPINAction, AppEnvironment> { _, _, _ in
    return .none
}.binding()

struct SetupTransportPIN: View {
    
    var store: Store<SetupTransportPINState, SetupTransportPINAction>
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    WithViewStore(store) { viewStore in
                        Text(L10n.FirstTimeUser.TransportPIN.title)
                            .font(.bundLargeTitle)
                            .foregroundColor(.blackish)
                        ZStack {
                            Image(decorative: "Transport-PIN")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                            PINEntryView(pin: viewStore.binding(\.$enteredPIN),
                                         maxDigits: 5,
                                         label: L10n.FirstTimeUser.TransportPIN.textFieldLabel,
                                         shouldBeFocused: viewStore.binding(\.$focusTextField),
                                         doneConfiguration: DoneConfiguration(enabled: viewStore.enteredPIN.count == 5,
                                                                              title: L10n.FirstTimeUser.TransportPIN.continue,
                                                                              handler: { _ in
                                    viewStore.send(.done)
                            }))
                            .font(.bundTitle)
                            .background(
                                Color.white.cornerRadius(10)
                            )
                            .padding(40)
                            // Focus: iOS 15 only
                            // Done button above keyboard: iOS 15 only
                        }
                        if viewStore.previouslyUnsuccessful {
                            VStack(spacing: 24) {
                                VStack {
                                    if viewStore.enteredPIN == "" {
                                        Text(L10n.FirstTimeUser.TransportPIN.Error.incorrectPIN)
                                            .font(.bundBodyBold)
                                            .foregroundColor(.red900)
                                        Text(L10n.FirstTimeUser.TransportPIN.Error.tryAgain)
                                            .font(.bundBody)
                                            .foregroundColor(.blackish)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(nil)
                                    }
                                    Text(L10n.FirstTimeUser.TransportPIN.remainingAttemptsLld(viewStore.remainingAttempts))
                                        .font(.bundBody)
                                        .foregroundColor(.blackish)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                }
                                Button {
                                    
                                } label: {
                                    Text(L10n.FirstTimeUser.TransportPIN.switchToPersonalPIN)
                                        .font(.bundBodyBold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SetupTransportPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupTransportPIN(store: Store(initialState: SetupTransportPINState(previouslyUnsuccessful: true),
                                                         reducer: .empty,
                                                         environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            SetupTransportPIN(store: Store(initialState: SetupTransportPINState(enteredPIN: "1234",
                                                                                                      previouslyUnsuccessful: true),
                                                         reducer: .empty,
                                                         environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            SetupTransportPIN(store: Store(initialState: SetupTransportPINState(enteredPIN: "1234",
                                                                                                      previouslyUnsuccessful: true),
                                                         reducer: .empty,
                                                         environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            SetupTransportPIN(store: Store(initialState: SetupTransportPINState(),
                                                         reducer: .empty,
                                                         environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
