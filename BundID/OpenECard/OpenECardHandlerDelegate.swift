import Foundation
import Combine
import OpenEcard

class OpenECardHandlerDelegate<S>: NSObject where S : Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    private let subscriber: S
    private let context: ContextManagerProtocol
    private var activationController: ActivationControllerProtocol?
    
    init(subscriber: S, context: ContextManagerProtocol) {
        self.subscriber = subscriber
        self.context = context
    }
    
    func send(event: EIDInteractionEvent) {
        _ = subscriber.receive(event)
    }
    
    func finish() {
        teardown()
        subscriber.receive(completion: .finished)
    }
    
    func fail(error: IDCardInteractionError) {
        teardown()
        subscriber.receive(completion: .failure(error))
    }
    
    private func teardown() {
        activationController?.cancelOngoingAuthentication()
        context.terminateContext(StopServiceHandler())
    }
}
