import Foundation
import OpenEcard

enum IDCardInteractionError: Error, Equatable {
    case frameworkError(message: String?)
    case unexpectedReadAttribute(String)
    case cardBlocked
    case cardDeactivated
    case processFailed(resultCode: ActivationResultCode, redirectURL: String?)
}
