import Foundation

struct IdentificationInformation: Equatable {
    let request: IdentificationRequest
    let certificateDescription: CertificateDescription
}

struct IdentificationRequest: Equatable {
    var requiredAttributes: [EIDAttribute]
    var transactionInfo: String?
}

struct CertificateDescription: Equatable {
    public let issuerName: String
    public let issuerURL: URL?
    public let purpose: String
    public let subjectName: String
    public let subjectURL: URL?
    public let termsOfUsage: String
    public let effectiveDate: Date
    public let expirationDate: Date
}
