import Foundation

enum EIDInteractionError: Error, Equatable {
    case unknownReader
    case frameworkError(message: String?)
    case unexpectedReadAttribute(String)
    case cardDeactivated
    case identificationFailed(resultMajor: String, resultMinor: String?, refreshURL: URL?)
    case pinChangeFailed
    case identificationFailedWithBadRequest
}

enum RedactedEIDInteractionError: CustomNSError, Hashable {
    // TODO: The message is lost, e.g. onWrapperError vs. onBadState
    case frameworkError
    case unexpectedReadAttribute
    case identificationFailed(resultMajor: String, resultMinor: String?)
    
    init?(_ eIDInteractionError: EIDInteractionError) {
        switch eIDInteractionError {
        case .frameworkError:
            self = .frameworkError
        case .unexpectedReadAttribute:
            self = .unexpectedReadAttribute
        case .identificationFailed(let resultMajor, let resultMinor, _):
            self = .identificationFailed(resultMajor: resultMajor, resultMinor: resultMinor)
        default:
            return nil
        }
    }
    
    var errorUserInfo: [String: Any] {
        switch self {
        case .frameworkError, .unexpectedReadAttribute:
            return [NSDebugDescriptionErrorKey: "\(self)"]
        case .identificationFailed(let resultMajor, let resultMinor):
            return [NSDebugDescriptionErrorKey: "identificationFailed(resultMajor: \(resultMajor), resultMinor: \(String(describing: resultMinor))"]
        }
    }
}
