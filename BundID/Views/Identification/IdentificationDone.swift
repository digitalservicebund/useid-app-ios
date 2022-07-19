import Foundation
import SwiftUI
import ComposableArchitecture

struct IdentificationDoneState: Equatable {
    var request: EIDAuthenticationRequest
}

enum IdentificationDoneAction: Equatable {
    case close
}

struct IdentificationDone: View {
    let store: Store<IdentificationDoneState, IdentificationDoneAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.Identification.Done.title,
                       message: L10n.Identification.Done.message(viewStore.request.subject),
                       imageMeta: nil,
                       secondaryButton: nil,
                       primaryButton: .init(title: L10n.Identification.Done.close,
                                            action: .close))
            .navigationBarBackButtonHidden(true)
        }
    }
}
