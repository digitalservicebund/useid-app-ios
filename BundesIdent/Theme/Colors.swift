import Foundation
import SwiftUI

extension Color {
    init(_ hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

public extension Color {
    static let blue100: Color = .init(0xF2F6F8)
    static let blue200: Color = .init(0xE0F1FB)
    static let blue300: Color = .init(0xDCE8EF)
    static let blue400: Color = .init(0xCCDBE4)
    static let blue500: Color = .init(0xB3C9D6)
    static let blue600: Color = .init(0x6693AD)
    static let blue700: Color = .init(0x336F91)
    static let blue800: Color = .init(0x004B76)
    static let blue900: Color = .init(0x003350)
    
    static let neutral100: Color = .init(0xF6F7F8)
    static let neutral300: Color = .init(0xEDEEF0)
    static let neutral400: Color = .init(0xDFE1E5)
    static let neutral600: Color = .init(0xB8BDC3)
    static let neutral900: Color = .init(0x4E596A)
    
    //  static let white: Color    = Color(0xFFFFFF)
    static let blackish: Color = .init(0x0B0C0C)
    
    static let green100: Color = .init(0xE8F7F0)
    static let green800: Color = .init(0x006538)
    
    static let orange400: Color = .init(0xCD7610)
    
    static let yellow200: Color = .init(0xFFF9D2)
    static let yellow600: Color = .init(0xF2DC5D)
    static let yellow900: Color = .init(0xA28C0D)
    
    static let red200: Color = .init(0xF9E5EC)
    static let red900: Color = .init(0x8E001B)
}
