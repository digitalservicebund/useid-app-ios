import Foundation

public struct CertificateDescription {
    public let issuerName: String
    public let issuerUrl: URL?
    public let purpose: String
    public let subjectName: String
    public let subjectUrl: URL?
    public let termsOfUsage: String
    public let effectiveDate: Date
    public let expirationDate: Date
}

enum EIDInteractionEvent: Equatable {
    case requestCardInsertion((String) -> Void) // kein Callback
    case cardInteractionComplete
    case cardRecognized
    case cardRemoved
    case requestCAN((_ can: String) -> Void) // kein Callback
    case requestPUK((String) -> Void) // kein Callback
    case authenticationSucceeded(redirectUrl: URL?) // combine processCompletedSuccessfullyWithoutRedirect and processCompletedSuccessfullyWithRedirect
    // case processCompletedSuccessfullyWithoutRedirect // onAuthCompleted ohne URL
    // case processCompletedSuccessfullyWithRedirect(url: URL) // onAuthCompleted mit URL
    case authenticationStarted
    case requestAuthenticationRequestConfirmation(AuthenticationRequest, (FlaggedAttributes) -> Void) // kein Callback
    // get rid off: case authenticationSuccessful
    case changingPINStarted // was pinManagementStarted
    case changingPINSucceeded // => success == true
    
    // NEW:
    case authenticationCertificate(CertificateDescription)
    
    // GET RID OF:
    case requestPINAndCAN((_ pin: String, _ can: String) -> Void)
    case requestPIN(remainingAttempts: Int?, pinCallback: (_ pin: String) -> Void)
    case requestChangedPIN(remainingAttempts: Int?, pinCallback: (_ oldPIN: String, _ newPIN: String) -> Void)
    case requestCANAndChangedPIN(pinCallback: (_ oldPIN: String, _ can: String, _ newPIN: String) -> Void)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.requestCardInsertion, .requestCardInsertion): return true
        case (.cardInteractionComplete, .cardInteractionComplete): return true
        case (.cardRecognized, .cardRecognized): return true
        case (.cardRemoved, .cardRemoved): return true
        case (.requestCAN, .requestCAN): return true
        case (.requestPIN(let lhsAttempts, _), .requestPIN(let rhsAttempts, _)):
            return lhsAttempts == rhsAttempts
        case (.requestPINAndCAN, .requestPINAndCAN): return true
        case (.requestPUK, .requestPUK): return true
        case (.processCompletedSuccessfullyWithoutRedirect, .processCompletedSuccessfullyWithoutRedirect): return true
        case (.processCompletedSuccessfullyWithRedirect(let lhsURL), .processCompletedSuccessfullyWithRedirect(let rhsURL)):
            return lhsURL == rhsURL
        case (.authenticationStarted, .authenticationStarted): return true
        case (.requestAuthenticationRequestConfirmation(let lhsRequest, _), .requestAuthenticationRequestConfirmation(let rhsRequest, _)): return lhsRequest == rhsRequest
        case (.authenticationSuccessful, .authenticationSuccessful): return true
        case (.pinManagementStarted, .pinManagementStarted): return true
        case (.requestChangedPIN(let lhsAttempts, _), .requestChangedPIN(let rhsAttempts, _)):
            return lhsAttempts == rhsAttempts
        case (.requestCANAndChangedPIN, .requestCANAndChangedPIN): return true
        default: return false
        }
    }
}

enum RedactedEIDInteractionEventError: CustomNSError {
    case requestCardInsertion
    case cardInteractionComplete
    case cardRecognized
    case cardRemoved
    case requestCAN
    case requestPIN
    case requestPINAndCAN
    case requestPUK
    case processCompletedSuccessfullyWithoutRedirect
    case processCompletedSuccessfullyWithRedirect
    case authenticationStarted
    case requestAuthenticationRequestConfirmation
    case authenticationSuccessful
    case pinManagementStarted
    case requestChangedPIN
    case requestCANAndChangedPIN
    
    init(_ eIDInteractionEvent: EIDInteractionEvent) {
        switch eIDInteractionEvent {
        case .requestCardInsertion: self = .requestCardInsertion
        case .cardInteractionComplete: self = .cardInteractionComplete
        case .cardRecognized: self = .cardRecognized
        case .cardRemoved: self = .cardRemoved
        case .requestCAN: self = .requestCAN
        case .requestPIN: self = .requestPIN
        case .requestPINAndCAN: self = .requestPINAndCAN
        case .requestPUK: self = .requestPUK
        case .processCompletedSuccessfullyWithoutRedirect: self = .processCompletedSuccessfullyWithoutRedirect
        case .processCompletedSuccessfullyWithRedirect: self = .processCompletedSuccessfullyWithRedirect
        case .authenticationStarted: self = .authenticationStarted
        case .requestAuthenticationRequestConfirmation: self = .requestAuthenticationRequestConfirmation
        case .authenticationSuccessful: self = .authenticationSuccessful
        case .pinManagementStarted: self = .pinManagementStarted
        case .requestChangedPIN: self = .requestChangedPIN
        case .requestCANAndChangedPIN: self = .requestCANAndChangedPIN
        }
    }
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: "\(self)"]
    }
}
