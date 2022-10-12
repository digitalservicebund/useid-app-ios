import SwiftUI

struct BoxContent: Hashable {
    enum Style: Hashable {
        case info
        case error
        
        var backgroundColor: Color {
            switch self {
            case .info: return .yellow200
            case .error: return .red200
            }
        }
        
        var iconColor: Color {
            switch self {
            case .info: return .blackish
            case .error: return .red900
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
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.circle")
                    .foregroundColor(content.style.iconColor)
                    .accessibilityHidden(true)
                Text(content.title)
            }
            .font(.bundSubtextBold)
            .foregroundColor(.blackish)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(content.message)
                .font(.bundSubtext)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.blackish)
        }
        .padding(16)
        .background(content.style.backgroundColor)
        .foregroundColor(content.style.backgroundColor)
        .cornerRadius(10)
    }
}

struct InfoBox_Previews: PreviewProvider {
    static var previews: some View {
        Box(content: BoxContent(title: "Info", message: "Message", style: .info))
        Box(content: BoxContent(title: "Error", message: "Message", style: .error))
    }
}
