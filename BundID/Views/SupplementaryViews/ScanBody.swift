import SwiftUI

struct ScanBody: View {
    
    let title: String
    let message: String
    let buttonTitle: String
    let buttonTapped: () -> Void
    let infoTapped: () -> Void
    let helpTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .font(.bundLargeTitle)
                .foregroundColor(.blackish)
            Button(buttonTitle,
                   action: buttonTapped)
            .buttonStyle(BundButtonStyle(isPrimary: true))
            Text(message)
                .font(.bundBody)
                .foregroundColor(.blackish)
            VStack(alignment: .leading, spacing: 16) {
                Button(action: infoTapped, label: {
                    Text(L10n.General.Scan.info)
                        .bold()
                })
                .padding(EdgeInsets(top: 8, leading: 10, bottom: 10, trailing: 8))
                .background(RoundedRectangle(cornerRadius: 12).foregroundColor(.blue200))
                Button(action: helpTapped, label: {
                    Text(L10n.General.Scan.help)
                        .bold()
                })
                .padding(EdgeInsets(top: 8, leading: 10, bottom: 10, trailing: 8))
                .background(RoundedRectangle(cornerRadius: 12).foregroundColor(.blue200))
            }
        }
        .padding()
    }
}
