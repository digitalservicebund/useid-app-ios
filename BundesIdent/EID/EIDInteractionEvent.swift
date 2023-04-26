import Foundation

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
