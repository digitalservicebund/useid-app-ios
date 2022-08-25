import Foundation
import SwiftUI
import ComposableArchitecture

struct IdentificationDoneState: Equatable {
    var request: EIDAuthenticationRequest
    var redirectURL: String
    
    var hasValidURL: Bool {
        if URL(string: redirectURL) != nil {
            return true
        }
        return false
    }
}

enum IdentificationDoneAction: Equatable {
    case close
    case openURL(URL)
}

struct IdentificationDone: View {
    let store: Store<IdentificationDoneState, IdentificationDoneAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.Identification.Done.title,
                       message: L10n.Identification.Done.message(viewStore.request.subject),
                       primaryButton: .init(title: L10n.Identification.Done.close,
                                            action: viewStore.hasValidURL ? .openURL(URL(string: viewStore.redirectURL)!) : .close))
            .navigationBarBackButtonHidden(true)
        }
    }
}
