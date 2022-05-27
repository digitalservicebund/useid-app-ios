import SwiftUI
import ComposableArchitecture

enum SetupPersonalPINIntroAction: Equatable {
    case `continue`
}

struct SetupPersonalPINIntro: View {
    
    var store: Store<Void, SetupPersonalPINIntroAction>
    
    var body: some View {
        DialogView(store: store,
                   titleKey: L10n.FirstTimeUser.PersonalPINIntro.title,
                   bodyKey: L10n.FirstTimeUser.PersonalPINIntro.body,
                   imageMeta: ImageMeta(name: "eIDs+PIN"),
                   secondaryButton: nil,
                   primaryButton: .init(title: L10n.FirstTimeUser.PersonalPINIntro.continue, action: .continue))
    }
}
