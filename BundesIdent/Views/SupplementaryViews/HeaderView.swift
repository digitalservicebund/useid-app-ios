import SwiftUI
import MarkdownUI

struct ImageMeta {
    let name: String
    let labelKey: String?
    let maxHeight: CGFloat?
    
    init(name: String, labelKey: String? = nil, maxHeight: CGFloat? = nil) {
        self.name = name
        self.labelKey = labelKey
        self.maxHeight = maxHeight
    }
    
    init(asset: ImageAsset, labelKey: String? = nil, maxHeight: CGFloat? = nil) {
        name = asset.name
        self.labelKey = labelKey
        self.maxHeight = maxHeight
    }
}

struct LinkMeta {
    let title: String
    let url: URL
}

struct HeaderView: View {
    var title: String
    var boxContent: BoxContent?
    var message: String?
    var imageMeta: ImageMeta?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text(title)
                    .headingXL()
                Spacer()
            }
            if let boxContent {
                Box(content: boxContent)
            }
            if let message {
                Markdown(message)
                    .markdownTheme(.bund)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let imageMeta {
                imageMeta.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: imageMeta.maxHeight)
                    .padding(.vertical, 10)
            }
        }
    }
    
    func attributed(message: String) -> AttributedString {
        (try? AttributedString(markdown: message,
                               options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))) ?? AttributedString(message)
    }
}

extension ImageMeta {
    var image: SwiftUI.Image {
        if let labelKey {
            return Image(name, label: Text(labelKey))
        } else {
            return Image(decorative: name)
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(title: L10n.FirstTimeUser.Intro.title,
                   message: L10n.FirstTimeUser.Intro.body,
                   imageMeta: ImageMeta(asset: Asset.pinBrief))
            .previewLayout(.sizeThatFits)
        HeaderView(title: "Some title")
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Title only")
    }
}
