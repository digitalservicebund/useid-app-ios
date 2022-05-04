//
//  Theme.swift
//  BundID
//
//  Created by Andreas Ganske on 02.05.22.
//

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

extension Color {
    static let blue100: Color = Color(0xF2F6F8)
    static let blue200: Color = Color(0xE0F1FB)
    static let blue300: Color = Color(0xDCE8EF)
    static let blue400: Color = Color(0xCCDBE4)
    static let blue500: Color = Color(0xB3C9D6)
    static let blue600: Color = Color(0x6693AD)
    static let blue700: Color = Color(0x336F91)
    static let blue800: Color = Color(0x004B76)
    static let blue900: Color = Color(0x003350)
    
    // static let white: Color   = Color(0xFFFFFF)
    static let gray100: Color = Color(0xF6F7F8)
    static let gray300: Color = Color(0xEDEEF0)
    static let gray600: Color = Color(0xB8BDC3)
    static let gray900: Color = Color(0x4E596A)
    static let blackish: Color   = Color(0x0B0C0C)
    
    static let green100: Color  = Color(0xE8F7F0)
    static let green800: Color  = Color(0x006538)
    static let yellow300: Color = Color(0xF9EC9E)
    static let yellow600: Color = Color(0xF2DC5D)
    static let red200: Color    = Color(0xF9E5EC)
    static let red900: Color    = Color(0x8E001B)
}
