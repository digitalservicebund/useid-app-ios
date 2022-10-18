import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPIN: View {
    var store: Store<SetupPersonalPINState, SetupPersonalPINAction>
    @FocusState private var focusedField: SetupPersonalPINState.Field?
    
    var body: some View {
        ScrollView {
            WithViewStore(store) { viewStore in
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.FirstTimeUser.PersonalPIN.title,
                               message: L10n.FirstTimeUser.PersonalPIN.body)
                    VStack {
                        Spacer()
                        PINEntryView(pin: viewStore.binding(\.$enteredPIN1),
                                     maxDigits: 6,
                                     groupEvery: 3,
                                     showPIN: false,
                                     label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.first,
                                     backgroundColor: .gray100,
                                     doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                          title: L10n.FirstTimeUser.PersonalPIN.continue,
                                                                          handler: { _ in
                            viewStore.send(.done(pin: viewStore.enteredPIN1))
                        }))
                        .focused($focusedField, equals: .pin1)
                        .font(.bundTitle)
                        .modifier(Shake(animatableData: CGFloat(viewStore.remainingAttempts)))
                        
                        if viewStore.showPIN2 {
                            VStack {
                                Spacer(minLength: 40)
                                Text(L10n.FirstTimeUser.PersonalPIN.confirmation)
                                    .font(.bundBody)
                                    .foregroundColor(.blackish)
                                    .fixedSize(horizontal: false, vertical: true)
                                PINEntryView(pin: viewStore.binding(\.$enteredPIN2),
                                             maxDigits: 6,
                                             groupEvery: 3,
                                             showPIN: false,
                                             label: L10n.FirstTimeUser.PersonalPIN.TextFieldLabel.second,
                                             backgroundColor: .gray100,
                                             doneConfiguration: DoneConfiguration(enabled: viewStore.doneButtonEnabled,
                                                                                  title: L10n.FirstTimeUser.PersonalPIN.continue,
                                                                                  handler: { _ in
                                    viewStore.send(.done(pin: viewStore.enteredPIN1))
                                }))
                                .focused($focusedField, equals: .pin2)
                                .font(.bundTitle)
                                .modifier(Shake(animatableData: CGFloat(viewStore.remainingAttempts)))
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
                .synchronize(viewStore.binding(\.$focusedField), $focusedField)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    viewStore.send(.onAppear)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SetupPersonalPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupPersonalPIN(store: Store(initialState: SetupPersonalPINState(enteredPIN1: "12345"),
                                          reducer: .empty,
                                          environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
