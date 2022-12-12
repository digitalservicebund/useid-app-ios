import SwiftUI

struct BundButtonStyle: ButtonStyle {
    
    var isPrimary = true
    var isOnDark = false
    @Environment(\.isEnabled) var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Spacer()
            configuration.label
                .bodyLBold(color: titleColor(configuration: configuration))
                .minimumScaleFactor(0.5)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(backgroundColor(configuration: configuration,
                                    isEnabled: isEnabled,
                                    isPrimary: isPrimary,
                                    isOnDark: isOnDark))
        .cornerRadius(10)
    }
    
    private func titleColor(configuration: Configuration) -> Color {
        guard isEnabled else {
            return .neutral900
        }
        
        if isPrimary {
            if isOnDark {
                return .blue800
            } else {
                return .white
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
}

struct BundTextButtonStyle: ButtonStyle {
    
    var isOnDark = false
    @Environment(\.isEnabled) var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .bodyLBold(color: titleColor(configuration: configuration))
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(backgroundColor(configuration: configuration,
                                        isEnabled: isEnabled,
                                        isPrimary: false,
                                        isOnDark: isOnDark))
            .cornerRadius(8)
    }
    
    private func titleColor(configuration: Configuration) -> Color {
        guard isEnabled else {
            return .neutral900
        }
        
        if configuration.isPressed {
            return isOnDark ? .blue800 : .blue800
        } else {
            return .blue800
        }
    }
}

private func backgroundColor(configuration: ButtonStyleConfiguration,
                             isEnabled: Bool,
                             isPrimary: Bool,
                             isOnDark: Bool) -> Color {
    guard isEnabled else {
        return .neutral300
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
