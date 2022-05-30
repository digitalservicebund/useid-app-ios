import Foundation
import Combine
import OpenEcard

class ControllerCallback: OpenECardHandlerBase, ControllerCallbackProtocol {
    func onStarted() {
        delegate.send(event: .authenticationStarted)
    }
    
    func onAuthenticationCompletion(_ result: (NSObjectProtocol & ActivationResultProtocol)!) {
        switch result.getCode() {
        case .OK, .REDIRECT:
            delegate.send(event: .processCompletedSuccessfully)
            delegate.finish()
        default:
            delegate.fail(error: .processFailed(resultCode: result.getCode()))
        }
    }
}
