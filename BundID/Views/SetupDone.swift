import SwiftUI
import ComposableArchitecture

enum SetupDoneAction: Equatable {
    case done
}

struct SetupDone: View {
    
    var store: Store<Void, SetupDoneAction>
    
    var body: some View {
        DialogView(store: store,
                   titleKey: "Einrichtung abgeschlossen",
                   bodyKey: nil,
                   imageMeta: nil,
                   secondaryButton: nil,
                   primaryButton: .init(title: "Schließen",
                                        action: .done))
        .navigationBarBackButtonHidden(true)
    }
}

struct SetupDone_Previews: PreviewProvider {
    static var previews: some View {
        SetupDone(store: .empty)
    }
}
