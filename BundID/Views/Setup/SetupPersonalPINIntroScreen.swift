import SwiftUI
import ComposableArchitecture

enum SetupPersonalPINIntroAction: Equatable {
    case `continue`
}

struct SetupPersonalPINIntro: View {
    
    var store: Store<Void, SetupPersonalPINIntroAction>
    
    var body: some View {
        DialogView(store: store,
                   title: L10n.FirstTimeUser.PersonalPINIntro.title,
                   message: L10n.FirstTimeUser.PersonalPINIntro.body,
                   imageMeta: ImageMeta(name: "eIDs+PIN"),
                   primaryButton: .init(title: L10n.FirstTimeUser.PersonalPINIntro.continue, action: .continue))
    }
}
