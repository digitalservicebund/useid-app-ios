import SwiftUI

struct ScanBody: View {
    
    let title: String
    let message: String
    let buttonTitle: String
    let buttonTapped: () -> Void
    let nfcInfoTapped: () -> Void
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
                Button(L10n.Scan.helpNFC, action: nfcInfoTapped)
                    .buttonStyle(BundTextButtonStyle())
                Button(L10n.Scan.helpScanning, action: helpTapped)
                    .buttonStyle(BundTextButtonStyle())
            }
        }
        .padding()
    }
}
