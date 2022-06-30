import Foundation
import SwiftUI
import ComposableArchitecture

struct IdentificationDoneState: Equatable {
    var subject: String
}

enum IdentificationDoneAction: Equatable {
    case close
}

struct IdentificationDone: View {
    let store: Store<IdentificationDoneState, IdentificationDoneAction>
    
    var body: some View {
        DialogView(store: store.stateless,
                   title: "Identifikation abgeschlossen",
                   message: nil,
                   imageMeta: nil,
                   secondaryButton: nil,
                   primaryButton: .init(title: "Schließen",
                                        action: .close))
            .navigationBarBackButtonHidden(true)
    }
}
