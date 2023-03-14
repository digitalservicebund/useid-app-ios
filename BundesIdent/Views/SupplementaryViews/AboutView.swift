import MarkdownUI
import SwiftUI

struct AboutView: View {
    let title: String
    let markdown: String
    
    var body: some View {
        ScrollView {
            HStack {
                Markdown(markdown)
                    .markdownTheme(.bund)
                    .padding(24)
                Spacer()
            }
        }
        .navigationTitle(Text(verbatim: title))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func attributed(message: String) -> AttributedString {
        do {
            return try AttributedString(markdown: message,
                                        options: .init(allowsExtendedAttributes: true, interpretedSyntax: .full))
        } catch {
            assertionFailure("Invalid markdown:\n\(message)")
            return AttributedString(message)
        }
    }
}

struct AboutView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            AboutView(title: L10n.Privacy.title,
                      markdown: L10n.Privacy.text)
        }
    }
}
