import Foundation
import Combine
import OpenEcard

class ControllerCallback: NSObject, ControllerCallbackType {
    
    private let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
    
    var publisher: EIDInteractionPublisher { subject.eraseToAnyPublisher() }
    
    func onStarted() {
        subject.send(.authenticationStarted)
    }
    
    func onAuthenticationCompletion(_ result: (NSObjectProtocol & ActivationResultProtocol)!) {
        switch (result.getCode(), result.getProcessResultMinor()) {
        case (.OK, _):
            subject.send(.processCompletedSuccessfullyWithoutRedirect)
            subject.send(completion: .finished)
        case (.REDIRECT, nil):
            subject.send(.processCompletedSuccessfullyWithRedirect(url: result.getRedirectUrl()))
            subject.send(completion: .finished)
        default:
            subject.send(completion: .failure(.processFailed(resultCode: result.getCode(),
                                                             redirectURL: result.getRedirectUrl(),
                                                             resultMinor: result.getProcessResultMinor())))
        }
    }
}
