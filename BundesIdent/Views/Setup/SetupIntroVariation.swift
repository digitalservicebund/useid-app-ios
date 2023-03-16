import SwiftUI
import ComposableArchitecture

struct SetupIntroVariationView: View {
    let store: Store<SetupIntro.State, SetupIntro.Action>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: "Online-Ausweis noch nicht eingerichtet?",
                       boxContent: .init(title: "Hinweis", message: "Falls Sie schon über eine persönliche 6-stellige PIN verfügen, ist Ihr Ausweis bereits eingerichtet.", style: .info),
                       imageMeta: ImageMeta(asset: Asset.eiDs),
                       secondaryButton: .init(title: L10n.FirstTimeUser.Intro.skipSetup,
                                              action: .chooseSkipSetup(tokenURL: viewStore.tokenURL)),
                       primaryButton: .init(title: L10n.FirstTimeUser.Intro.startSetup,
                                            action: .chooseStartSetup))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.General.cancel) {
                            dismiss()
                        }
                        .bodyLRegular(color: .accentColor)
                    }
                }
        }
    }
}

struct SetupIntroVariationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupIntroVariationView(store: Store(initialState: SetupIntro.State(tokenURL: nil),
                                                 reducer: SetupIntro()))
        }
        .previewDevice("iPhone SE (2nd generation)")
        
        NavigationView {
            SetupIntroVariationView(store: Store(initialState: SetupIntro.State(tokenURL: nil),
                                                 reducer: SetupIntro()))
        }
        .previewDevice("iPhone 12")
    }
}
