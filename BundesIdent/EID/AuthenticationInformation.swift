import Foundation

struct AuthenticationInformation: Equatable {
    let request: AuthenticationRequest
    let certificateDescription: CertificateDescription
}

struct AuthenticationRequest: Equatable {
    var requiredAttributes: [EIDAttribute]
    var transactionInfo: String?
}

struct CertificateDescription: Equatable {
    public let issuerName: String
    public let issuerUrl: URL?
    public let purpose: String
    public let subjectName: String
    public let subjectUrl: URL?
    public let termsOfUsage: String
    public let effectiveDate: Date
    public let expirationDate: Date
}
