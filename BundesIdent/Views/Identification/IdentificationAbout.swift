import SwiftUI
import ComposableArchitecture

struct IdentificationAbout: View {
    
    // TODO: We do not handle the purpose string, effective date and expirationDate
    var request: CertificateDescription
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(request.subjectName)
                    .headingXL()
                
                Text(L10n.Identification.AttributeConsentInfo.providerInfo)
                    .headingL()
                
                Text(L10n.Identification.AttributeConsentInfo.provider)
                    .headingM()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.subjectName)
                    Text(request.subjectUrl?.absoluteString ?? "") // TODO: Handle with an if?
                }
                .bodyLRegular()
                
                Text(L10n.Identification.AttributeConsentInfo.issuer)
                    .headingM()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.issuerName)
                    Text(request.issuerUrl?.absoluteString ?? "") // TODO: Handle with an if?
                }
                .bodyLRegular()
                
                Text(L10n.Identification.AttributeConsentInfo.terms)
                    .headingM()
                
                Text(request.termsOfUsage)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .bodyLRegular()
            }
            .padding(.horizontal)
        }
    }
}

#if PREVIEW

struct IdentificationAbout_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationAbout(request: .preview)
    }
}

#endif
