import Foundation
import Combine
import OpenEcard

class OpenECardHandlerDelegate: NSObject {
    private let subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>
    private let context: ContextManagerProtocol
    private var activationController: ActivationControllerProtocol?
    
    init(subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>, context: ContextManagerProtocol) {
        self.subject = subject
        self.context = context
    }
    
    func send(event: EIDInteractionEvent) {
        subject.send(event)
    }
    
    func finish() {
        teardown()
        subject.send(completion: .finished)
    }
    
    func fail(error: IDCardInteractionError) {
        teardown()
        subject.send(completion: .failure(error))
    }
    
    private func teardown() {
        activationController?.cancelOngoingAuthentication()
        context.terminateContext(StopServiceHandler())
    }
}
