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

#if !targetEnvironment(simulator)
    init(_ description: AusweisApp2SDKWrapper.CertificateDescription) {
        self.issuerName = description.issuerName
        self.issuerUrl = description.issuerUrl
        self.purpose = description.purpose
        self.subjectName = description.subjectName
        self.subjectUrl = description.subjectUrl
        self.termsOfUsage = description.termsOfUsage
        self.effectiveDate = description.validity.effectiveDate
        self.expirationDate = description.validity.expirationDate
    }
#endif
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
}

enum EIDInteractionEvent: Equatable {
    case cardInsertionRequested
    case cardInteractionCompleted
    case cardRecognized
    case cardRemoved
    case canRequested
    case pinRequested(remainingAttempts: Int?)
    case newPINRequested
    case pukRequested
    case authenticationStarted
    case authenticationSucceeded(redirectUrl: URL?)
    case authenticationRequestConfirmationRequested(AuthenticationRequest)
    case pinChangeStarted
    case pinChangeSucceeded
    case certificateDescriptionRetrieved(CertificateDescription)
}

enum RedactedEIDInteractionEventError: CustomNSError {
    case cardInsertionRequested
    case cardInteractionCompleted
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
        case .cardInteractionCompleted: self = .cardInteractionCompleted
        case .cardRecognized: self = .cardRecognized
        case .cardRemoved: self = .cardRemoved
        case .canRequested: self = .canRequested
        case .pinRequested: self = .pinRequested
        case .newPINRequested: self = .newPINRequested
        case .pukRequested: self = .pukRequested
        case .authenticationStarted: self = .authenticationStarted
        case .authenticationSucceeded(redirectUrl: .some): self = .authenticationSucceededWithRedirect
        case .authenticationSucceeded(redirectUrl: .none): self = .authenticationSucceededWithoutRedirect
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
