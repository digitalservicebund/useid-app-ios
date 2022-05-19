import Foundation
import Combine
import OpenEcard

class ControllerCallback<S>: OpenECardHandlerBase<S>, ControllerCallbackProtocol where S: Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
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
