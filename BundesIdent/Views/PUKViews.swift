import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct PUKCoordinatorView: View {
    let store: Store<PUKCoordinator.State, PUKCoordinator.Action>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /PUKScreen.State.pinLetter,
                        action: PUKScreen.Action.pinLetter,
                        then: PUKPINLetterView.init)
                CaseLet(state: /PUKScreen.State.pukInput,
                        action: PUKScreen.Action.pukInput,
                        then: {
                            InputView(
                                input: .puk,
                                title: L10n.Input.Puk.title,
                                message: L10n.Input.Puk.body,
                                store: $0
                            )
                        })
                CaseLet(state: /PUKScreen.State.scan,
                        action: PUKScreen.Action.scan,
                        then: PUKScanView.init)
            }
        }
        .alert(store.scope(state: \.alert), dismiss: PUKCoordinator.Action.dismissAlert)
        .interactiveDismissDisabled()
    }
}

struct PUKPINLetterView: View {
    
    var store: Store<PUKPINLetter.State, PUKPINLetter.Action>
    
    var body: some View {
        DialogView(store: store.stateless,
                   title: L10n.FirstTimeUser.MissingPINLetter.title,
                   message: L10n.FirstTimeUser.MissingPINLetter.body,
                   imageMeta: ImageMeta(asset: Asset.missingPINBrief),
                   secondaryButton: .init(title: L10n.Puk.PinLetter.letterUnavailable,
                                          action: .letterUnavailable),
                   primaryButton: .init(title: L10n.Puk.PinLetter.letterAvailable,
                                        action: .letterAvailable))
    }
}

struct PUKPINLetterView_Previews: PreviewProvider {
    static var previews: some View {
        PUKPINLetterView(store: Store(initialState: PUKPINLetter.State(),
                                      reducer: PUKPINLetter()))
    }
}

struct PUKScanView: View {
    
    var store: Store<PUKScan.State, PUKScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: PUKScan.Action.shared))
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        ViewStore(store).send(.cancelTapped)
                    }
                }
            }
    }
}

#if DEBUG

struct PUKScan_Previews: PreviewProvider {
    static var previews: some View {
        PUKScanView(store: Store(initialState: PUKScan.State(),
                                 reducer: PUKScan()))
    }
}

#endif
