import Foundation
import Combine
import OpenEcard

class IDInteractionManager: IDInteractionManagerType {
    
    private let context: ContextManagerProtocol
    
    init() {
        let openEcard = OpenEcardImp()!
        context = openEcard.context(NFSMessageProvider())!
    }
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        let delegate: OpenECardHandlerDelegate = OpenECardHandlerDelegate(subject: subject, context: context)
        context.initializeContext(StartServiceHandler(task: .eac(tokenURL: tokenURL), delegate: delegate))
        return subject.eraseToAnyPublisher()
    }
    
    func changePIN() -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        let delegate: OpenECardHandlerDelegate = OpenECardHandlerDelegate(subject: subject, context: context)
        context.initializeContext(StartServiceHandler(task: .pinManagement, delegate: delegate))
        return subject.eraseToAnyPublisher()
    }
}
