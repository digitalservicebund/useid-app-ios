import SwiftUI

extension Font {
    /// 30pt – bold
    static let bundLargeTitle: Font = .custom("BundesSans", size: 30, relativeTo: .largeTitle).bold()
    
    /// 26pt – bold
    static let bundTitle: Font = .custom("BundesSans", size: 26, relativeTo: .title).bold()
    
    /// 20pt – bold
    static let bundHeader: Font = .custom("BundesSans", size: 20, relativeTo: .headline).bold()
    
    /// 18pt – bold
    static let bundBodyBold: Font = .custom("BundesSans", size: 18, relativeTo: .body).bold()
    
    /// 18pt – regular
    static let bundBody: Font = .custom("BundesSans", size: 18, relativeTo: .body)
    
    /// 16pt – bold
    static let bundSubtextBold: Font = .custom("BundesSans", size: 16, relativeTo: .footnote).bold()
    
    /// 16pt – regular
    static let bundSubtext: Font = .custom("BundesSans", size: 16, relativeTo: .footnote)
    
    /// 14pt – regular
    static let bundCaption1: Font = .custom("BundesSans", size: 14, relativeTo: .caption)
    
    /// 12pt – regular
    static let bundCaption2: Font = .custom("BundesSans", size: 12, relativeTo: .caption2)
}
