import ComposableArchitecture
import SwiftUI

struct DialogView<Action>: View {
    var store: Store<Void, Action>
    var title: String
    var boxContent: BoxContent?
    var message: String?
    var imageMeta: ImageMeta?
    var secondaryButton: DialogButtons<Action>.ButtonConfiguration?
    var primaryButton: DialogButtons<Action>.ButtonConfiguration?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                HeaderView(title: title,
                           boxContent: boxContent,
                           message: message,
                           imageMeta: imageMeta)
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
            DialogButtons(store: store,
                          secondary: secondaryButton,
                          primary: primaryButton)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogView<DialogButtonsPreviewAction>(store: .empty,
                                               title: "Titel",
                                               message: "Lorem ipsum dolor set amet",
                                               imageMeta: ImageMeta(asset: Asset.eiDs),
                                               secondaryButton: .init(title: "Secondary", action: .secondary),
                                               primaryButton: .init(title: "Primary", action: .primary))
    }
}
