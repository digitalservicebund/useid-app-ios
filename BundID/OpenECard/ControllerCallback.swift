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
        let redirectURL = result.getRedirectUrl().flatMap(URL.init(string:))
        
        switch (result.getCode(), result.getProcessResultMinor(), redirectURL) {
        case (.OK, _, _):
            subject.send(.processCompletedSuccessfullyWithoutRedirect)
            subject.send(completion: .finished)
        case (.REDIRECT, nil, .some(let url)):
            subject.send(.processCompletedSuccessfullyWithRedirect(url: url))
            subject.send(completion: .finished)
        default:
            subject.send(completion: .failure(.processFailed(resultCode: result.getCode(),
                                                             redirectURL: redirectURL,
                                                             resultMinor: result.getProcessResultMinor())))
        }
    }
}
