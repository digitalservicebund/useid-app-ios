import SwiftUI
import ComposableArchitecture

struct IdentificationAbout: View {
    
    var request: EIDAuthenticationRequest
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(request.subject)
                    .font(.bundTitle)
                Text(L10n.Identification.About.subjectInformation)
                    .font(.bundLargeTitle)
                
                Text(L10n.Identification.About.subject)
                    .font(.bundHeader)
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.subject)
                    Text(request.subjectURL)
                }
                .font(.bundBody)
                
                Text(L10n.Identification.About.issuer)
                    .font(.bundHeader)
                VStack(alignment: .leading, spacing: 0) {
                    Text(request.issuer)
                    Text(request.issuerURL)
                }
                .font(.bundBody)
                
                Text(L10n.Identification.About.terms)
                    .font(.bundHeader)
                Text(request.terms.description)
                    .font(.bundBody)
            }
            .foregroundColor(.blackish)
            .padding(.horizontal)
        }
    }
}
