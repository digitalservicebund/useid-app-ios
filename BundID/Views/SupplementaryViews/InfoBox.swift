import SwiftUI

struct InfoBoxContent: Hashable {
    let title: String
    let message: String
}

struct InfoBox: View {
    let content: InfoBoxContent
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(Image(systemName: "exclamationmark.circle"))  \(content.title)")
                .font(.bundSubtextBold)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(content.message)
                .font(.bundSubtext)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(0xFBF4CE))
        .foregroundColor(Color(0x5F5208))
        .cornerRadius(10)
    }
}

struct InfoBox_Previews: PreviewProvider {
    static var previews: some View {
        InfoBox(content: InfoBoxContent(title: "Title", message: "Message"))
    }
}
