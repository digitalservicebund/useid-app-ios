import SwiftUI
import ComposableArchitecture

struct SetupIntro: ReducerProtocol {
    enum Action: Equatable {
        case chooseSkipSetup(tokenURL: URL?)
        case chooseStartSetup
    }

    struct State: Equatable {
        var tokenURL: URL?
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}

struct SetupIntroView: View {
    let store: Store<SetupIntro.State, SetupIntro.Action>
    @Environment(\.dismiss) private var dismiss
    
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

struct SetupIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SetupIntroView(store: Store(initialState: SetupIntro.State(tokenURL: nil),
                                    reducer: SetupIntro()))
        }
        .previewDevice("iPhone SE (2nd generation)")
        
        NavigationView {
            SetupIntroView(store: Store(initialState: SetupIntro.State(tokenURL: nil),
                                    reducer: SetupIntro()))
        }
        .previewDevice("iPhone 12")
    }
}
