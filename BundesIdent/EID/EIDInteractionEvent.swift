import Foundation
#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper
#endif

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

#if !targetEnvironment(simulator)
extension CertificateDescription {
    init(_ description: AusweisApp2SDKWrapper.CertificateDescription) {
        issuerName = description.issuerName
        issuerUrl = description.issuerUrl
        purpose = description.purpose
        subjectName = description.subjectName
        subjectUrl = description.subjectUrl
        termsOfUsage = description.termsOfUsage
        effectiveDate = description.validity.effectiveDate
        expirationDate = description.validity.expirationDate
    }
}
#endif

struct AuthenticationInformation: Equatable {
    let request: AuthenticationRequest
    let certificateDescription: CertificateDescription
}

struct AuthenticationRequest: Equatable {
    var requiredAttributes: [IDCardAttribute]
    var transactionInfo: String?
}

struct ScanOverlayMessages: Equatable {
    let sessionStarted: String
    let sessionFailed: String
    let sessionSucceeded: String
    let sessionInProgress: String

    // TODO: Update keys for single scan
    static let setup: Self = .init(sessionStarted: L10n.FirstTimeUser.Scan.ProvideCard.first,
                                   sessionFailed: L10n.CardInteraction.Error.default,
                                   sessionSucceeded: L10n.FirstTimeUser.Scan.ScanSuccess.second,
                                   sessionInProgress: L10n.FirstTimeUser.Scan.CardRecognized.first)
    static let identification: Self = .init(sessionStarted: L10n.Identification.Scan.provideCard,
                                            sessionFailed: L10n.CardInteraction.Error.default,
                                            sessionSucceeded: L10n.Identification.Scan.scanSuccess,
                                            sessionInProgress: L10n.Identification.Scan.cardRecognized)
}

enum EIDInteractionEvent: Equatable {
    case cardInsertionRequested
    case cardRecognized
    case cardRemoved
    case canRequested
    case pinRequested(remainingAttempts: Int?)
    case newPINRequested
    case pukRequested
    case authenticationStarted
    case authenticationSucceeded(redirectURL: URL?)
    case authenticationRequestConfirmationRequested(AuthenticationRequest)
    case pinChangeStarted
    case pinChangeSucceeded
    case certificateDescriptionRetrieved(CertificateDescription)
}

enum RedactedEIDInteractionEventError: CustomNSError {
    case cardInsertionRequested
    case cardRecognized
    case cardRemoved
    case canRequested
    case pinRequested
    case newPINRequested
    case pukRequested
    case authenticationStarted
    case authenticationSucceededWithRedirect
    case authenticationSucceededWithoutRedirect
    case authenticationRequestConfirmationRequested
    case pinChangeStarted
    case pinChangeSucceeded
    case certificateDescriptionRetrieved
    
    init(_ eIDInteractionEvent: EIDInteractionEvent) {
        switch eIDInteractionEvent {
        case .cardInsertionRequested: self = .cardInsertionRequested
        case .cardRecognized: self = .cardRecognized
        case .cardRemoved: self = .cardRemoved
        case .canRequested: self = .canRequested
        case .pinRequested: self = .pinRequested
        case .newPINRequested: self = .newPINRequested
        case .pukRequested: self = .pukRequested
        case .authenticationStarted: self = .authenticationStarted
        case .authenticationSucceeded(redirectURL: .some): self = .authenticationSucceededWithRedirect
        case .authenticationSucceeded(redirectURL: .none): self = .authenticationSucceededWithoutRedirect
        case .authenticationRequestConfirmationRequested: self = .authenticationRequestConfirmationRequested
        case .pinChangeStarted: self = .pinChangeStarted
        case .pinChangeSucceeded: self = .pinChangeSucceeded
        case .certificateDescriptionRetrieved: self = .certificateDescriptionRetrieved
        }
    }
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: "\(self)"]
    }
}
