import SwiftUI

struct ScanBody: View {
    
    struct ButtonConfiguration {
        let title: String
        let action: () -> Void
    }
    
    let title: String
    let message: String
    let primaryButton: ButtonConfiguration?
    let nfcInfoTapped: () -> Void
    let helpTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(title)
                .headingXL()
            if let primaryButton {
                Button(primaryButton.title, action: primaryButton.action)
                    .buttonStyle(BundButtonStyle(isPrimary: true))
            }
            Text(message)
                .bodyLRegular()
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
