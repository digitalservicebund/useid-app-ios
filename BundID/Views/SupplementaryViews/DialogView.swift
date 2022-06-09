import SwiftUI
import ComposableArchitecture

struct DialogView<Action>: View {
    var store: Store<Void, Action>
    var titleKey: String
    var bodyKey: String?
    var imageMeta: ImageMeta?
    var linkMeta: LinkMeta?
    var secondaryButtonConfiguration: DialogButtons<Action>.ButtonConfiguration?
    var primaryButtonConfiguration: DialogButtons<Action>.ButtonConfiguration?
    
    init(store: Store<Void, Action>,
         titleKey: String,
         bodyKey: String?,
         imageMeta: ImageMeta? = nil,
         linkMeta: LinkMeta? = nil,
         secondaryButton: DialogButtons<Action>.ButtonConfiguration? = nil,
         primaryButton: DialogButtons<Action>.ButtonConfiguration?) {
        self.store = store
        self.titleKey = titleKey
        self.bodyKey = bodyKey
        self.imageMeta = imageMeta
        self.linkMeta = linkMeta
        self.secondaryButtonConfiguration = secondaryButton
        self.primaryButtonConfiguration = primaryButton
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                HeaderView(titleKey: titleKey,
                           bodyKey: bodyKey,
                           imageMeta: imageMeta,
                           linkMeta: linkMeta)
            }
            DialogButtons(store: store,
                          secondary: secondaryButtonConfiguration,
                          primary: primaryButtonConfiguration)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DialogView_Previews: PreviewProvider {
    static var previews: some View {
        DialogView<DialogButtonsPreviewAction>(store: .empty,
                                               titleKey: "Titel",
                                               bodyKey: "Lorem ipsum dolor set amet",
                                               imageMeta: ImageMeta(name: "eIDs"),
                                               secondaryButton: .init(title: "Secondary", action: .secondary),
                                               primaryButton: .init(title: "Primary", action: .primary))
    }
}
