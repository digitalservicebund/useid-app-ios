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
                Button(L10n.General.Scan.info, action: infoTapped)
                    .buttonStyle(BundTextButtonStyle())
                Button(L10n.General.Scan.help, action: helpTapped)
                    .buttonStyle(BundTextButtonStyle())
            }
        }
        .padding()
    }
}
