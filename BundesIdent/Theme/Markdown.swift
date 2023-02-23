import MarkdownUI

extension Theme {

    static let bund = Theme
        .basic
        .text {
            FontProperties.bodyLRegular
            ForegroundColor(.blackish)
        }
        .link {
            FontWeight(.bold)
            ForegroundColor(.accentColor)
        }
        .listItem {
            $0.markdownMargin(top: .em(0.7))
        }
        .paragraph {
            $0.markdownMargin(top: .zero, bottom: .em(1.4))
        }
}
