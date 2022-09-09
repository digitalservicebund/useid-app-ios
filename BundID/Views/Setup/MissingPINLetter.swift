import SwiftUI
import ComposableArchitecture
import Analytics

struct MissingPINLetterState: Equatable {}

enum MissingPINLetterAction: Equatable {
    case openExternalLink
}

let missingPINLetterReducer = Reducer<MissingPINLetterState, MissingPINLetterAction, AppEnvironment> { _, action, environment in
    switch action {
    case .openExternalLink:
        return .fireAndForget {
            let event = AnalyticsEvent(category: "firstTimeUser",
                                       action: "externalLinkOpened",
                                       name: "PINLetter")
            environment.analytics.track(event: event)
        }
    }
}

struct MissingPINLetter: View {
    let store: Store<MissingPINLetterState, MissingPINLetterAction>
    
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
        MissingPINLetter(store: Store(initialState: MissingPINLetterState(),
                                      reducer: .empty,
                                      environment: AppEnvironment.preview))
    }
}
