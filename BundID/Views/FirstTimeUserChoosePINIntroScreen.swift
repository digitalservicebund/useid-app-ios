import SwiftUI
import ComposableArchitecture

enum FirstTimeUserChoosePINIntroAction: Equatable {
    case `continue`
}

struct FirstTimeUserChoosePINIntroScreen: View {
    
    var store: Store<Void, FirstTimeUserChoosePINIntroAction>
    
    var body: some View {
        DialogView(store: store,
                   titleKey: L10n.FirstTimeUser.PersonalPINIntro.title,
                   bodyKey: L10n.FirstTimeUser.PersonalPINIntro.body,
                   imageMeta: ImageMeta(name: "eIDs+PIN"),
                   secondaryButton: nil,
                   primaryButton: .init(title: L10n.FirstTimeUser.PersonalPINIntro.continue, action: .continue))
    }
}
