import SwiftUI

struct ScanBody: View {
    
    let helpTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(L10n.Scan.title)
                .headingXL()
            Text(L10n.Scan.body)
                .bodyLRegular()
            VStack(alignment: .leading, spacing: 16) {
                Button(L10n.Scan.helpScanning, action: helpTapped)
                    .buttonStyle(BundTextButtonStyle())
            }
        }
        .padding()
    }
}
