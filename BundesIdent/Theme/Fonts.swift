import SwiftUI
import MarkdownUI

private let bundFontName = "BundesSans"

extension Font {
    static func bundCustom(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom(bundFontName, size: size, relativeTo: textStyle)
    }
}

extension UIFont {
    convenience init(descriptor: UIFontDescriptor) {
        self.init(descriptor: descriptor, size: descriptor.pointSize)
    }
    static var bundNavigationBar: UIFont {
        var descriptor = UIFontDescriptor(name: bundFontName, size: 17)
        if UIAccessibility.isBoldTextEnabled {
            descriptor = descriptor.withSymbolicTraits(.traitBold)!
        }
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: .init(descriptor: descriptor))
    }
    
    static var bundNavigationBarBold: UIFont {
        var descriptor = UIFontDescriptor(name: bundFontName, size: 17)
        descriptor = descriptor.withSymbolicTraits(.traitBold)!
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: .init(descriptor: descriptor))
    }
}

extension MarkdownStyle.Font {
    
    /// 18pt – regular
    static let bundBody = MarkdownStyle.Font.custom(bundFontName, size: 18)
}

extension View {
    /// heading-xl
    /// 30/36
    /// bold
    public func headingXL(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 30, relativeTo: .largeTitle).bold().leading(.loose))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// heading-l
    /// 26/32
    /// bold
    public func headingL(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 26, relativeTo: .title).bold().leading(.loose))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// heading-m
    /// 20/24
    /// bold
    public func headingM(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 24, relativeTo: .headline).bold().leading(.standard))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// body-l
    /// 18/24
    /// bold
    public func bodyLBold(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 18, relativeTo: .body).bold().leading(.standard))
            .foregroundColor(color)
    }
    
    /// body-l
    /// 18/24
    /// regular
    public func bodyLRegular(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 18, relativeTo: .body).leading(.standard))
            .foregroundColor(color)
    }
    
    /// body-l
    /// 16/20
    /// bold
    public func bodyMBold(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 16, relativeTo: .body).bold().leading(.standard))
            .foregroundColor(color)
    }
    
    /// body-l
    /// 16/20
    /// regular
    public func bodyMRegular(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 16, relativeTo: .body).leading(.standard))
            .foregroundColor(color)
    }
    
    /// caption-l
    /// 14/18
    /// regular
    public func captionL(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 14, relativeTo: .caption).leading(.standard))
            .foregroundColor(color)
    }
    
    /// caption-m
    /// 12/14
    /// regular
    public func captionM(color: Color? = .blackish) -> some View {
        self
            .font(.custom(bundFontName, size: 12, relativeTo: .caption2).leading(.standard))
            .foregroundColor(color)
    }
}
