import SwiftUI
import ComposableArchitecture

enum SetupIntroAction: Equatable {
    case chooseSetupAlreadyDone
    case chooseSetupNotDoneYet
}

struct SetupIntro: View {
    
    var store: Store<Void, SetupIntroAction>
    
    var body: some View {
        DialogView(store: store,
                   title: L10n.FirstTimeUser.Intro.title,
                   message: L10n.FirstTimeUser.Intro.body,
                   imageMeta: ImageMeta(name: "eIDs"),
                   secondaryButton: .init(title: L10n.FirstTimeUser.Intro.yes, action: .chooseSetupAlreadyDone),
                   primaryButton: .init(title: L10n.FirstTimeUser.Intro.no, action: .chooseSetupNotDoneYet))
    }
}

struct SetupIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupIntro(store: Store(initialState: (), reducer: .empty, environment: AppEnvironment.preview))
        }
            .previewDevice("iPhone SE (2nd generation)")
        NavigationView {
            SetupIntro(store: Store(initialState: (), reducer: .empty, environment: AppEnvironment.preview))
        }
            .previewDevice("iPhone 12")
    }
}
