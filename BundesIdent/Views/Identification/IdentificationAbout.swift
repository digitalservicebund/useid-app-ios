import SwiftUI
import ComposableArchitecture

struct IdentificationAbout: View {
    
    var request: CertificateDescription
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(request.subjectName)
                    .headingXL()
                
                Text(L10n.Identification.AttributeConsentInfo.providerInfo)
                    .headingL()

                block(header: L10n.Identification.AttributeConsentInfo.provider,
                      texts: [request.subjectName, request.subjectURL?.absoluteString])

                block(header: L10n.Identification.AttributeConsentInfo.issuer,
                      texts: [request.issuerName, request.issuerURL?.absoluteString])

                block(header: L10n.Identification.AttributeConsentInfo.purpose,
                      texts: [request.purpose])

                block(header: L10n.Identification.AttributeConsentInfo.terms,
                      texts: [request.termsOfUsage])

                block(header: L10n.Identification.AttributeConsentInfo.validity,
                      texts: [[request.effectiveDate, request.expirationDate]
                        .map { "\($0.formatted(date: .numeric, time: .omitted))" }
                        .joined(separator: " - ")])
            }
            .padding(.horizontal)
        }
    }

    private func block(header: String, texts: [String?]) -> some View {
        return Group {
            Text(header)
                .headingM()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(texts.compactMap { $0 }, id: \.self) {
                    Text($0)
                }
            }
            .bodyLRegular()
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
