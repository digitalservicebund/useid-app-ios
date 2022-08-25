import SwiftUI
import ComposableArchitecture

enum SetupTransportPINIntroAction: Equatable {
    case availablePINLetter
    case missingPINLetter
}

struct SetupTransportPINIntro: View {
    
    var store: Store<Void, SetupTransportPINIntroAction>
    
    var body: some View {
        DialogView(store: store,
                   title: L10n.FirstTimeUser.PinLetter.title,
                   message: L10n.FirstTimeUser.PinLetter.body,
                   imageMeta: ImageMeta(name: "PIN-Brief",
                                        maxHeight: 300.0),
                   secondaryButton: .init(title: L10n.FirstTimeUser.PinLetter.yes, action: .availablePINLetter),
                   primaryButton: .init(title: L10n.FirstTimeUser.PinLetter.no, action: .missingPINLetter))
    }
}

struct SetupTransportPINIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupTransportPINIntro(store: .empty)
        }
        .environment(\.sizeCategory, .extraExtraExtraLarge)
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            SetupTransportPINIntro(store: .empty)
        }
        .previewDevice("iPhone 12")
    }
}
