import SwiftUI

private let bundFontName = "BundesSans"

extension View {
    /// heading-xl
    /// 30/36
    /// bold
    public func headingXL() -> some View {
        self
            .font(.custom(bundFontName, size: 30, relativeTo: .largeTitle).bold().leading(.loose))
            .foregroundColor(.blackish)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// heading-l
    /// 26/32
    /// bold
    public func headingL() -> some View {
        self
            .font(.custom(bundFontName, size: 26, relativeTo: .title).bold().leading(.loose))
            .foregroundColor(.blackish)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// heading-m
    /// 20/24
    /// bold
    public func headingM() -> some View {
        self
            .font(.custom(bundFontName, size: 24, relativeTo: .headline).bold().leading(.standard))
            .foregroundColor(.blackish)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// body-l
    /// 18/24
    /// bold
    public func bodyLBold() -> some View {
        self
            .font(.custom(bundFontName, size: 18, relativeTo: .body).bold().leading(.standard))
            .foregroundColor(.blackish)
    }
    
    /// body-l
    /// 18/24
    /// regular
    public func bodyLRegular() -> some View {
        self
            .font(.custom(bundFontName, size: 18, relativeTo: .body).leading(.standard))
            .foregroundColor(.blackish)
    }
    
    /// body-l
    /// 16/20
    /// bold
    public func bodyMBold() -> some View {
        self
            .font(.custom(bundFontName, size: 16, relativeTo: .body).bold().leading(.standard))
            .foregroundColor(.blackish)
    }
    
    /// body-l
    /// 16/20
    /// regular
    public func bodyMRegular() -> some View {
        self
            .font(.custom(bundFontName, size: 16, relativeTo: .body).leading(.standard))
            .foregroundColor(.blackish)
    }
    
    /// caption-l
    /// 14/18
    /// regular
    public func captionL() -> some View {
        self
            .font(.custom(bundFontName, size: 14, relativeTo: .caption).leading(.standard))
            .foregroundColor(.blackish)
    }
    
    /// caption-m
    /// 12/14
    /// regular
    public func captionM() -> some View {
        self
            .font(.custom(bundFontName, size: 12, relativeTo: .caption2).leading(.standard))
            .foregroundColor(.blackish)
    }
}
