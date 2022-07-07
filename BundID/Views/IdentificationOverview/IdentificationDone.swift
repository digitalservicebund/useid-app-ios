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
                       title: "Identifikation abgeschlossen",
                       message: "Machen Sie weiter bei \(viewStore.request.subject).",
                       imageMeta: nil,
                       secondaryButton: nil,
                       primaryButton: .init(title: "Schließen",
                                            action: .close))
            .navigationBarBackButtonHidden(true)
        }
    }
}
