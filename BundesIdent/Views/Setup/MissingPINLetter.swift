import SwiftUI
import ComposableArchitecture
import Analytics

struct MissingPINLetter: ReducerProtocol {
    @Dependency(\.analytics) var analytics: AnalyticsClient
    
    struct State: Equatable {}

    enum Action: Equatable {
        case openExternalLink
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .openExternalLink:
            return .trackEvent(category: "firstTimeUser",
                               action: "externalLinkOpened",
                               name: "PINLetter",
                               analytics: analytics)
        }
    }
}

struct MissingPINLetterView: View {
    let store: Store<MissingPINLetter.State, MissingPINLetter.Action>
    
    var body: some View {
        DialogView(store: store.stateless,
                   title: L10n.FirstTimeUser.MissingPINLetter.title,
                   message: L10n.FirstTimeUser.MissingPINLetter.body,
                   imageMeta: ImageMeta(asset: Asset.missingPINBrief))
            .environment(\.openURL, OpenURLAction { _ in
                ViewStore(store.stateless).send(.openExternalLink)
                return .systemAction
            })
    }
}

struct MissingPINLetter_Previews: PreviewProvider {
    static var previews: some View {
        MissingPINLetterView(store: Store(initialState: MissingPINLetter.State(),
                                          reducer: MissingPINLetter()))
    }
}
