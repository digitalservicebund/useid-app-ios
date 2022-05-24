import SwiftUI
import Combine
import ComposableArchitecture

enum FirstTimeUserPersonalPINScreenError {
    case mismatch
}

struct FirstTimeUserPersonalPINScreen: View {
    
    var store: Store<FirstTimeUserPersonalPINState, FirstTimeUserPersonalPINAction>
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.FirstTimeUser.PersonalPIN.title)
                        .font(.bundLargeTitle)
                        .foregroundColor(.blackish)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredPIN1),
                                     maxDigits: 6,
                                     groupEvery: 3,
                                     showPIN: false,
                                     label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first,
                                     shouldBeFocused: viewStore.binding(\.$focusPIN1),
                                     doneConfiguration: nil)
                        .font(.bundTitle)
                        .modifier(Shake(animatableData: CGFloat(viewStore.attempts)))
                        if viewStore.showPIN2 {
                            VStack {
                                Spacer(minLength: 40)
                                Text(L10n.FirstTimeUser.PersonalPIN.confirmation)
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                PINEntryView(pin: viewStore.binding(\.$enteredPIN2),
                                             maxDigits: 6,
                                             groupEvery: 3,
                                             showPIN: false,
                                             label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second,
                                             shouldBeFocused: viewStore.binding(\.$focusPIN2),
                                             doneConfiguration: nil)
                                .font(.bundTitle)
                                .modifier(Shake(animatableData: CGFloat(viewStore.attempts)))
                                Spacer()
                            }
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    
                    if case .mismatch = viewStore.error {
                        SetupPersonalPINErrorView(title: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title,
                                                  message: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.body)
                    }
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

struct FirstTimeUserPersonalPINScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserPersonalPINScreen(store: Store(initialState: FirstTimeUserPersonalPINState(enteredPIN1: "12345"), reducer: .empty, environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
