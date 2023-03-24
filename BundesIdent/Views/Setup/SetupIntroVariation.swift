import SwiftUI
import ComposableArchitecture
import MarkdownUI

struct SetupIntroVariationView: View {
    let store: Store<SetupIntro.State, SetupIntro.Action>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(L10n.FirstTimeUser.Intro.titleVariation)
                            .headingXL()
                        VStack(alignment: .center, spacing: 0) {
                            Markdown(L10n.FirstTimeUser.Intro.box)
                                .markdownTheme(.bund)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(16)
                                .foregroundColor(.blackish)
                            Image(decorative: Asset.pinSetupIOS.name)
                                .padding(.bottom, 16)
                        }
                        .background(Color.blue300)
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                DialogButtons(store: store.stateless,
                              secondary: .init(title: L10n.FirstTimeUser.Intro.skipSetup,
                                               action: .chooseSkipSetup(tokenURL: viewStore.tokenURL)),
                              primary: .init(title: L10n.FirstTimeUser.Intro.startSetup,
                                             action: .chooseStartSetup))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        dismiss()
                    }
                    .bodyLRegular(color: .accentColor)
                }
            }
            .ignoresSafeArea(.keyboard)
            .navigationBarTitleDisplayMode(.inline)
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
        .environment(\.locale, .init(identifier: "en"))
    }
}
