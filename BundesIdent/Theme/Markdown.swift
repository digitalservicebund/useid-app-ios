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
}
