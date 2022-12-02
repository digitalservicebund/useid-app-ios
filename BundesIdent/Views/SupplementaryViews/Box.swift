import SwiftUI

struct BoxContent: Hashable {
    enum Style: Hashable {
        case info
        case warning
        case error
        case success
        
        var backgroundColor: Color {
            switch self {
            case .info: return .blue200
            case .warning: return .yellow200
            case .error: return .red200
            case .success: return .green100
            }
        }
        
        var iconColor: Color {
            switch self {
            case .info: return .blue700
            case .warning: return .orange400
            case .error: return .red900
            case .success: return .green800
            }
        }
        
        var iconSystemName: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }
    }
    
    let title: String
    let message: String
    let style: Style
}

struct Box: View {
    let content: BoxContent
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: content.style.iconSystemName)
                .foregroundColor(content.style.iconColor)
                .accessibilityHidden(true)
            VStack(spacing: 4) {
                Text(content.title)
                    .bodyMBold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(content.message)
                    .bodyMRegular()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(content.style.backgroundColor)
        .foregroundColor(content.style.backgroundColor)
        .cornerRadius(10)
    }
}

struct InfoBox_Previews: PreviewProvider {
    
    static var message = "Body text describing the alert."
    
    static var previews: some View {
        VStack(spacing: 8) {
            Box(content: BoxContent(title: "Informational message", message: message, style: .info))
            Box(content: BoxContent(title: "Warning message", message: message, style: .warning))
            Box(content: BoxContent(title: "Error message", message: message, style: .error))
            Box(content: BoxContent(title: "Success message", message: message, style: .success))
        }
        .padding()
    }
}
