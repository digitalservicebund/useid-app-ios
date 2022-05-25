import SwiftUI
import ComposableArchitecture

enum FirstTimeUserPINLetterAction: Equatable {
    case chooseHasPINLetter
    case chooseHasNoPINLetter
}

struct FirstTimeUserPINLetterScreen: View {
    
    var store: Store<Void, FirstTimeUserPINLetterAction>
    
    var body: some View {
        DialogView(store: store,
                   titleKey: L10n.FirstTimeUser.PinLetter.title,
                   bodyKey: L10n.FirstTimeUser.PinLetter.body,
                   imageMeta: ImageMeta(name: "PIN-Brief"),
                   secondaryButton: .init(title: L10n.FirstTimeUser.PinLetter.yes, action: .chooseHasPINLetter),
                   primaryButton: .init(title: L10n.FirstTimeUser.PinLetter.no, action: .chooseHasNoPINLetter))
    }
}

struct FirstTimeUserPINLetterScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FirstTimeUserPINLetterScreen(store: .empty)
        }
        .environment(\.sizeCategory, .extraExtraExtraLarge)
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            FirstTimeUserPINLetterScreen(store: .empty)
        }
        .previewDevice("iPhone 12")
    }
}
