import SwiftUI

extension Font {
    /// 30pt – bold
    static let bundLargeTitle: Font = .custom(fontName, size: 30, relativeTo: .largeTitle).bold()
    
    /// 26pt – bold
    static let bundTitle: Font = .custom(fontName, size: 26, relativeTo: .title).bold()
    
    /// 20pt – bold
    static let bundHeader: Font = .custom(fontName, size: 20, relativeTo: .headline).bold()
    
    /// 18pt – bold
    static let bundBodyBold: Font = .custom(fontName, size: 18, relativeTo: .body).bold()
    
    /// 18pt – regular
    static let bundBody: Font = .custom(fontName, size: 18, relativeTo: .body)
    
    /// 16pt – bold
    static let bundSubtextBold: Font = .custom(fontName, size: 16, relativeTo: .footnote).bold()
    
    /// 16pt – regular
    static let bundSubtext: Font = .custom(fontName, size: 16, relativeTo: .footnote)
    
    /// 14pt – regular
    static let bundCaption1: Font = .custom(fontName, size: 14, relativeTo: .caption)
    
    /// 12pt – regular
    static let bundCaption2: Font = .custom(fontName, size: 12, relativeTo: .caption2)
    
    static func bundCustom(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom(fontName, size: size, relativeTo: textStyle)
    }
    
    private static let fontName = "BundesSans"
}
