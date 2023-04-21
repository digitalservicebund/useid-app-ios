import Foundation

enum ActivationResultCode: String {
    case INTERNAL_ERROR
    case DEPENDING_HOST_UNREACHABLE
    case CLIENT_ERROR
    case BAD_REQUEST
}

enum EIDInteractionError: Error, Equatable {
    case unknownReader
    case frameworkError(message: String?)
    case unexpectedReadAttribute(String)
    case cardBlocked
    case cardDeactivated
    case authenticationFailed(resultMajor: String, resultMinor: String?, refreshURL: URL?)
    case pinChangeFailed
    case authenticationBadRequest
}

enum RedactedEIDInteractionError: CustomNSError, Hashable {
    // TODO: The message is lost, e.g. onWrapperError vs. onBadState
    case frameworkError
    case unexpectedReadAttribute
    case authenticationFailed(resultMajor: String, resultMinor: String?)
    
    init?(_ eIDInteractionError: EIDInteractionError) {
        switch eIDInteractionError {
        case .frameworkError:
            self = .frameworkError
        case .unexpectedReadAttribute:
            self = .unexpectedReadAttribute
        case .authenticationFailed(let resultMajor, let resultMinor, _):
            self = .authenticationFailed(resultMajor: resultMajor, resultMinor: resultMinor)
        default:
            return nil
        }
    }
    
    var errorUserInfo: [String: Any] {
        switch self {
        case .frameworkError, .unexpectedReadAttribute:
            return [NSDebugDescriptionErrorKey: "\(self)"]
        case .authenticationFailed(let resultMajor, let resultMinor):
            return [NSDebugDescriptionErrorKey: "authenticationFailed(resultMajor: \(resultMajor), resultMinor: \(String(describing: resultMinor))"]
        }
    }
}
