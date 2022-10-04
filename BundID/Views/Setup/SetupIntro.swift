import SwiftUI
import ComposableArchitecture

enum SetupIntroAction: Equatable {
    case chooseSkipSetup(tokenURL: URL?)
    case chooseStartSetup
}

struct SetupIntroState: Equatable {
    var tokenURL: URL?
}

struct SetupIntro: View {
    let store: Store<SetupIntroState, SetupIntroAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.FirstTimeUser.Intro.title,
                       message: L10n.FirstTimeUser.Intro.body,
                       imageMeta: ImageMeta(asset: Asset.eiDs),
                       secondaryButton: .init(title: L10n.FirstTimeUser.Intro.skipSetup,
                                              action: .chooseSkipSetup(tokenURL: viewStore.tokenURL)),
                       primaryButton: .init(title: L10n.FirstTimeUser.Intro.startSetup,
                                            action: .chooseStartSetup))
        }
    }
}

struct SetupIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupIntro(store: Store(initialState: SetupIntroState(tokenURL: nil),
                                    reducer: .empty,
                                    environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone SE (2nd generation)")
        
        NavigationView {
            SetupIntro(store: Store(initialState: SetupIntroState(tokenURL: nil),
                                    reducer: .empty,
                                    environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
