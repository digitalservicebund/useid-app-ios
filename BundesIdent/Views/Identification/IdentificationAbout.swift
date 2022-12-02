import SwiftUI
import ComposableArchitecture

struct IdentificationAbout: View {
    
    var request: EIDAuthenticationRequest
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(request.subject)
                    .headingXL()
                
                Text(L10n.Identification.AttributeConsentInfo.providerInfo)
                    .headingL()
                
                Text(L10n.Identification.AttributeConsentInfo.provider)
                    .headingM()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.subject)
                    Text(request.subjectURL)
                }
                .bodyLRegular()
                
                Text(L10n.Identification.AttributeConsentInfo.issuer)
                    .headingM()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.issuer)
                    Text(request.issuerURL)
                }
                .bodyLRegular()
                
                Text(L10n.Identification.AttributeConsentInfo.terms)
                    .headingM()
                
                Text(request.terms.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bodyLRegular()
            }
            .padding(.horizontal)
        }
    }
}
