import SwiftUI
import ComposableArchitecture

enum SetupTransportPINIntroAction: Equatable {
    case choosePINLetterAvailable
    case choosePINLetterMissing
}

struct SetupTransportPINIntroView: View {
    
    var store: Store<Void, SetupTransportPINIntroAction>
    
    var body: some View {
        DialogView(store: store,
                   title: L10n.FirstTimeUser.PinLetter.title,
                   message: L10n.FirstTimeUser.PinLetter.body,
                   imageMeta: ImageMeta(asset: Asset.pinBrief, maxHeight: 300.0),
                   secondaryButton: .init(title: L10n.FirstTimeUser.PinLetter.requestLetter, action: .choosePINLetterMissing),
                   primaryButton: .init(title: L10n.FirstTimeUser.PinLetter.letterPresent, action: .choosePINLetterAvailable))
        .interactiveDismissDisabled()
    }
}

struct SetupTransportPINIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupTransportPINIntroView(store: .empty)
        }
        .environment(\.sizeCategory, .extraExtraExtraLarge)
        .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            SetupTransportPINIntroView(store: .empty)
        }
        .previewDevice("iPhone 12")
    }
}
