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
}
