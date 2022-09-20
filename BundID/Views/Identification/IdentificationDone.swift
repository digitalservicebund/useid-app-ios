import Foundation
import SwiftUI
import ComposableArchitecture

struct IdentificationDoneState: Equatable {
    var request: EIDAuthenticationRequest
    var redirectURL: String
    
    var hasValidURL: Bool {
        URL(string: redirectURL) != nil
    }
}

enum IdentificationDoneAction: Equatable {
    case close
    case openURL(URL)
}

let identificationDoneReducer = Reducer<IdentificationDoneState, IdentificationDoneAction, AppEnvironment> { _, action, environment in
    switch action {
    case .openURL(let url):
        return Effect.concatenate(
            .openURL(url, urlOpener: environment.urlOpener),
            .trackEvent(category: "identification",
                        action: "buttonPressed",
                        name: "continueToService",
                        analytics: environment.analytics)
        )
    default:
        return .none
    }
}

struct IdentificationDone: View {
    let store: Store<IdentificationDoneState, IdentificationDoneAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.Identification.Done.title,
                       message: L10n.Identification.Done.body(viewStore.request.subject),
                       primaryButton: .init(title: L10n.Identification.Done.continue,
                                            action: viewStore.hasValidURL ? .openURL(URL(string: viewStore.redirectURL)!) : .close))
            .navigationBarBackButtonHidden(true)
        }
        .navigationBarHidden(false)
    }
}
