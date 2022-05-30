import Foundation
import Combine
import OpenEcard

class OpenECardHandlerDelegate: NSObject {
    private let subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>
    private let context: ContextManagerProtocol
    
    init(context: ContextManagerProtocol) {
        self.subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.context = context
    }
    
    var publisher: EIDInteractionPublisher {
        subject.eraseToAnyPublisher()
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
        context.terminateContext(StopServiceHandler())
    }
}
