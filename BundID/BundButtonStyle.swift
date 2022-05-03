//
//  BundButtonStyle.swift
//  BundID
//
//  Created by Andreas Ganske on 02.05.22.
//

import SwiftUI

struct BundButtonStyle: ButtonStyle {
    
    var isPrimary: Bool = true
    var isOnDark: Bool = false
    @Environment(\.isEnabled) var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .font(Font.bundBodyBold)
                .minimumScaleFactor(0.5)
                .foregroundColor(titleColor(configuration: configuration))
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            backgroundColor(configuration: configuration)
            .cornerRadius(10)
        )
    }
    
    func titleColor(configuration: Configuration) -> Color {
        guard isEnabled else {
            return .gray900
        }
        
        if isPrimary {
            if isOnDark {
                if configuration.isPressed {
                    return .blue800
                } else {
                    return .blue800
                }
            } else {
                if configuration.isPressed {
                    return .blue900
                } else {
                    return .white
                }
            }
        } else {
            if isOnDark {
                if configuration.isPressed {
                    return .blue900
                } else {
                    return .blue800
                }
            } else {
                if configuration.isPressed {
                    return .blue900
                } else {
                    return .blue800
                }
            }
        }
    }
    
    func backgroundColor(configuration: Configuration) -> Color {
        guard isEnabled else {
            return .gray300
        }
        
        if isPrimary {
            if isOnDark {
                if configuration.isPressed {
                    return .blue200
                } else {
                    return .white
                }
            } else {
                if configuration.isPressed {
                    return .blue900
                } else {
                    return .blue800
                }
            }
        } else {
            if isOnDark {
                if configuration.isPressed {
                    return .blue500
                } else {
                    return .blue300
                }
            } else {
                if configuration.isPressed {
                    return .blue300
                } else {
                    return .blue200
                }
            }
        }
    }
}
