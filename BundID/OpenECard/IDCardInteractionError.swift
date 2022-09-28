import Foundation
import OpenEcard

enum IDCardInteractionError: Error, Equatable {
    case frameworkError(message: String?)
    case unexpectedReadAttribute(String)
    case cardBlocked
    case cardDeactivated
    case processFailed(resultCode: ActivationResultCode, redirectURL: String?, resultMinor: String?)
}

enum RedactedIDCardInteractionError: CustomNSError, Hashable {
    case frameworkError
    case unexpectedReadAttribute
    case processFailed(resultCode: ActivationResultCode, resultMinor: String?)
    
    init?(_ idCardInteractionError: IDCardInteractionError) {
        switch idCardInteractionError {
        case .frameworkError:
            self = .frameworkError
        case .unexpectedReadAttribute:
            self = .unexpectedReadAttribute
        case .processFailed(let resultCode, _, let resultMinor):
            self = .processFailed(resultCode: resultCode, resultMinor: resultMinor)
        default:
            return nil
        }
    }
    
    var errorUserInfo: [String: Any] {
        switch self {
        case .frameworkError, .unexpectedReadAttribute:
            return [NSDebugDescriptionErrorKey: "\(self)"]
        case .processFailed(let resultCode, let resultMinor):
            return [NSDebugDescriptionErrorKey: "processFailed(resultCode: \(resultCode.rawValue), resultMinor: \(String(describing: resultMinor))"]
        }
    }
}
