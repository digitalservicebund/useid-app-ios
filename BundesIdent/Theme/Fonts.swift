import SwiftUI
import MarkdownUI

let bundFontName = "BundesSans"

extension Font {
    static func bundCustom(size: CGFloat, relativeTo textStyle: Font.TextStyle) -> Font {
        .custom(bundFontName, size: size, relativeTo: textStyle)
    }
}

extension UIFont {
    convenience init(descriptor: UIFontDescriptor) {
        self.init(descriptor: descriptor, size: descriptor.pointSize)
    }
    
    static var bundBodyLRegular: UIFont {
        var descriptor = UIFontDescriptor(name: bundFontName, size: 18)
        if UIAccessibility.isBoldTextEnabled {
            descriptor = descriptor.withSymbolicTraits(.traitBold)!
        }
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: .init(descriptor: descriptor))
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

extension MarkdownUI.FontProperties {
    
    /// body-l
    /// 18/24
    /// regular
    static let bodyLRegular: Self = .init(family: .custom(bundFontName), size: 18)
}

public extension View {
    /// heading-xl
    /// 30/36
    /// bold
    func headingXL(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 30, relativeTo: .largeTitle).bold().leading(.loose))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// heading-l
    /// 26/32
    /// bold
    func headingL(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 26, relativeTo: .title).bold().leading(.loose))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// heading-m
    /// 20/24
    /// bold
    func headingM(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 24, relativeTo: .headline).bold().leading(.standard))
            .foregroundColor(color)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// body-l
    /// 18/24
    /// bold
    func bodyLBold(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 18, relativeTo: .body).bold().leading(.standard))
            .foregroundColor(color)
    }
    
    /// body-l
    /// 18/24
    /// regular
    func bodyLRegular(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 18, relativeTo: .body).leading(.standard))
            .foregroundColor(color)
    }
    
    /// body-m
    /// 16/20
    /// bold
    func bodyMBold(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 16, relativeTo: .body).bold().leading(.standard))
            .foregroundColor(color)
    }
    
    /// body-m
    /// 16/20
    /// regular
    func bodyMRegular(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 16, relativeTo: .body).leading(.standard))
            .foregroundColor(color)
    }
    
    /// caption-l
    /// 14/18
    /// regular
    func captionL(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 14, relativeTo: .caption).leading(.standard))
            .foregroundColor(color)
    }
    
    /// caption-m
    /// 12/14
    /// regular
    func captionM(color: Color? = .blackish) -> some View {
        font(.custom(bundFontName, size: 12, relativeTo: .caption2).leading(.standard))
            .foregroundColor(color)
    }

    /// 17/22
    /// regular
    func bundNavigationBar() -> some View {
        var customFont = Font.custom(bundFontName, size: 17, relativeTo: .body).leading(.standard)
        if UIAccessibility.isBoldTextEnabled {
            customFont = customFont.bold()
        }
        return font(customFont).foregroundColor(.accentColor)
    }

    /// 17/22
    /// bold
    func bundNavigationBarBold() -> some View {
        font(.custom(bundFontName, size: 17, relativeTo: .body).bold().leading(.standard)).foregroundColor(.accentColor)
    }
}
