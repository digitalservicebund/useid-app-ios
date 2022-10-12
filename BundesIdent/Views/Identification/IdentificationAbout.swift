import SwiftUI
import ComposableArchitecture

struct IdentificationAbout: View {
    
    var request: EIDAuthenticationRequest
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(request.subject)
                    .font(.bundLargeTitle)
                
                Text(L10n.Identification.AttributeConsentInfo.providerInfo)
                    .font(.bundTitle)
                
                Text(L10n.Identification.AttributeConsentInfo.provider)
                    .font(.bundHeader)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.subject)
                    Text(request.subjectURL)
                }
                .font(.bundBody)
                
                Text(L10n.Identification.AttributeConsentInfo.issuer)
                    .font(.bundHeader)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.issuer)
                    Text(request.issuerURL)
                }
                .font(.bundBody)
                
                Text(L10n.Identification.AttributeConsentInfo.terms)
                    .font(.bundHeader)
                
                Text(request.terms.description)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.bundBody)
            }
            .foregroundColor(.blackish)
            .padding(.horizontal)
        }
    }
}
