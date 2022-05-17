import Foundation

enum EIDInteractionEvent {
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
}
