import Foundation

struct EIDAuthenticationRequest: Equatable {
    let issuer: String
    let issuerURL: String
    let subject: String
    let subjectURL: String
    let validity: String
    let terms: AuthenticationTerms
    let readAttributes: FlaggedAttributes
}
