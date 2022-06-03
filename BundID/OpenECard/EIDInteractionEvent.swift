import Foundation

enum EIDInteractionEvent: Equatable {
    case requestCardInsertion((String) -> Void)
    case cardInteractionComplete
    case cardRecognized
    case cardRemoved
    case requestCAN((String) -> Void)
    case requestPIN(attempts: Int?, pinCallback: (String) -> Void)
    case requestPINAndCAN((String, String) -> Void)
    case requestPUK((String) -> Void)
    case processCompletedSuccessfully
    case authenticationStarted
    case requestAuthenticationRequestConfirmation(EIDAuthenticationRequest, (FlaggedAttributes) -> Void)
    case authenticationSuccessful
    case pinManagementStarted
    case requestChangedPIN(attempts: Int?, pinCallback: (String, String) -> Void)
    case requestCANAndChangedPIN(pinCallback: (String, String, String) -> Void)
    
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
        case (.processCompletedSuccessfully, .processCompletedSuccessfully): return true
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
