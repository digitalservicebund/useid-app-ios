import Foundation
import CombineSchedulers
import Combine

struct MockIDInteractionManager: IDInteractionManagerType {
    var queue: AnySchedulerOf<DispatchQueue>
    
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        queue.schedule {
            subject.send(.authenticationStarted)
            subject.send(completion: .failure(.frameworkError(message: "Not implemented")))
        }
        return subject.eraseToAnyPublisher()
    }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        subject.send(completion: .failure(.frameworkError(message: "Not implemented")))
        return subject.eraseToAnyPublisher()
    }
    
    func setPIN(pin: String) {
        // not implemented
    }
    
    func retrieveCertificateDescription() {
        // not implemented
    }
    
    func acceptAccessRights() {
        // not implemented
    }
    
    func interrupt() {
        // not implemented
    }
    
    func cancel() {
        // not implemented
    }
}
