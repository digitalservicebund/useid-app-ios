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
                   boxContent: .init(title: L10n.FirstTimeUser.PersonalPINIntro.Info.title,
                                     message: L10n.FirstTimeUser.PersonalPINIntro.Info.body,
                                     style: .info),
                   imageMeta: ImageMeta(asset: Asset.eiDsPIN),
                   primaryButton: .init(title: L10n.FirstTimeUser.PersonalPINIntro.continue,
                                        action: .continue))
    }
}
