import SwiftUI

struct ImageMeta {
    let name: String
    let labelKey: String? = nil
}

struct LinkMeta {
    let title: String
    let url: URL
}

struct HeaderView: View {
    
    var titleKey: String
    var bodyKey: String?
    var imageMeta: ImageMeta?
    var linkMeta: LinkMeta?
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(titleKey)
                    .font(.bundLargeTitle)
                    .foregroundColor(.blackish)
                    .padding(.bottom, 24)
                if let body = bodyKey {
                    Text(body)
                        .font(.bundBody)
                        .foregroundColor(.blackish)
                }
                if let linkMeta = linkMeta {
                    Link(linkMeta.title, destination: linkMeta.url)
                        .font(.bundBody)
                }
            }
            .padding()
            if let imageMeta = imageMeta {
                imageMeta.image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
        }
    }
}

extension ImageMeta {
    var image: Image {
        if let labelKey = labelKey {
            return Image(name, label: Text(labelKey))
        } else {
            return Image(decorative: name)
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(titleKey: L10n.FirstTimeUser.Intro.title,
                   bodyKey: L10n.FirstTimeUser.Intro.body,
                   imageMeta: ImageMeta(name: "PIN-Brief"),
                   linkMeta: LinkMeta(title: "Behördenfinder", url: URL(string: "https://behoerdenfinder.de")!))
        .previewLayout(.sizeThatFits)
    }
}
