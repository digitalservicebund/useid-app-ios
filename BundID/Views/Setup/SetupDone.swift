import SwiftUI
import ComposableArchitecture

enum SetupDoneAction: Equatable {
    case done
}

struct SetupDone: View {
    
    var store: Store<Void, SetupDoneAction>
    
    var body: some View {
        DialogView(store: store,
                   title: L10n.FirstTimeUser.Done.title,
                   message: nil,
                   imageMeta: ImageMeta(name: "eIDs"),
                   secondaryButton: nil,
                   primaryButton: .init(title: L10n.FirstTimeUser.Done.close,
                                        action: .done))
        .navigationBarBackButtonHidden(true)
    }
}

struct SetupDone_Previews: PreviewProvider {
    static var previews: some View {
        SetupDone(store: .empty)
    }
}
