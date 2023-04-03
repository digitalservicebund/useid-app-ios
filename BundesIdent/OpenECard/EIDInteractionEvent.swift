import Foundation

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

struct AuthenticationRequest: Equatable {
    var requiredAttributes: [IDCardAttribute]
    var transactionInfo: String?
    var certificateDescription: CertificateDescription
}

struct ScanOverlayMessages: Equatable {
    let sessionStarted: String
    let sessionFailed: String
    let sessionSucceeded: String
    let sessionInProgress: String
}

enum EIDInteractionEvent: Equatable {
    case interactionStarted
    case cardInsertionRequested // TODO: Rename android
    case cardInteractionCompleted // TODO: Rename android
    case cardRecognized
    case cardRemoved
    case canRequested // TODO: Rename on android
    case pinRequested(remainingAttempts: Int?) // TODO: Rename on android
    case pukRequested // TODO: Rename on android
    case authenticationStarted
    case authenticationSucceeded(redirectUrl: URL?) // TODO: Tell android to remove suffix "WithRedirect"
    case authenticationRequestConfirmationRequested(AuthenticationRequest) // TODO: Rename on android
    case changingPINStarted // was pinManagementStarted
    case changingPINSucceeded
    case certificateDescriptionRetrieved(CertificateDescription) // TODO: Rename on android
}

enum RedactedEIDInteractionEventError: CustomNSError {
    case cardInsertionRequested
    case cardInteractionCompleted
    case cardRecognized
    case cardRemoved
    case canRequested
    case pinRequested
    case pukRequested
    case authenticationStarted
    case authenticationSucceededWithRedirect
    case authenticationSucceededWithoutRedirect
    case authenticationRequestConfirmationRequested
    case changingPINStarted
    case changingPINSucceeded
    case certificateDescriptionRetrieved
    
    init(_ eIDInteractionEvent: EIDInteractionEvent) {
        switch eIDInteractionEvent {
        case .cardInsertionRequested: self = .cardInsertionRequested
        case .cardInteractionCompleted: self = .cardInteractionCompleted
        case .cardRecognized: self = .cardRecognized
        case .cardRemoved: self = .cardRemoved
        case .canRequested: self = .canRequested
        case .pinRequested: self = .pinRequested
        case .pukRequested: self = .pukRequested
        case .authenticationStarted: self = .authenticationStarted
        case .authenticationSucceeded(redirectUrl: .some): self = .authenticationSucceededWithRedirect
        case .authenticationSucceeded(redirectUrl: .none): self = .authenticationSucceededWithoutRedirect
        case .authenticationRequestConfirmationRequested: self = .authenticationRequestConfirmationRequested
        case .changingPINStarted: self = .changingPINStarted
        case .changingPINSucceeded: self = .changingPINSucceeded
        case .certificateDescriptionRetrieved: self = .certificateDescriptionRetrieved
        }
    }
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: "\(self)"]
    }
}
