import Foundation

enum EIDInteractionEvent: Equatable {
    case cardInsertionRequested
    case cardRecognized
    case cardRemoved
    case canRequested
    case pinRequested(remainingAttempts: Int?)
    case newPINRequested
    case pukRequested
    case identificationStarted
    case identificationSucceeded(redirectURL: URL?)
    case identificationRequestConfirmationRequested(IdentificationRequest)
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
    case identificationStarted
    case identificationSucceededWithRedirect
    case identificationSucceededWithoutRedirect
    case identificationRequestConfirmationRequested
    case pinChangeStarted
    case pinChangeSucceeded
    case certificateDescriptionRetrieved
    
    init(_ event: EIDInteractionEvent) {
        switch event {
        case .cardInsertionRequested: self = .cardInsertionRequested
        case .cardRecognized: self = .cardRecognized
        case .cardRemoved: self = .cardRemoved
        case .canRequested: self = .canRequested
        case .pinRequested: self = .pinRequested
        case .newPINRequested: self = .newPINRequested
        case .pukRequested: self = .pukRequested
        case .identificationStarted: self = .identificationStarted
        case .identificationSucceeded(redirectURL: .some): self = .identificationSucceededWithRedirect
        case .identificationSucceeded(redirectURL: .none): self = .identificationSucceededWithoutRedirect
        case .identificationRequestConfirmationRequested: self = .identificationRequestConfirmationRequested
        case .pinChangeStarted: self = .pinChangeStarted
        case .pinChangeSucceeded: self = .pinChangeSucceeded
        case .certificateDescriptionRetrieved: self = .certificateDescriptionRetrieved
        }
    }
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: "\(self)"]
    }
}
