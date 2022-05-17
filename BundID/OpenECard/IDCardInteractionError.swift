import Foundation
import OpenEcard

enum IDCardInteractionError: Error {
    case frameworkError(message: String?)
    case unexpectedReadAttribute(String)
    case cardBlocked
    case cardDeactivated
    case processFailed(resultCode: ActivationResultCode)
}
