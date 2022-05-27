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
        IDCardTaskPublisher(task: .eac(tokenURL: tokenURL), context: context).eraseToAnyPublisher()
    }
    
    func changePIN() -> EIDInteractionPublisher {
        IDCardTaskPublisher(task: .pinManagement, context: context)
            .eraseToAnyPublisher()
    }
    
    private struct IDCardTaskPublisher: Publisher {
        typealias Output = EIDInteractionEvent
        typealias Failure = IDCardInteractionError
        
        let task: IDTask
        let context: ContextManagerProtocol
        
        func receive<S>(subscriber: S) where S: Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
            let delegate = OpenECardHandlerDelegate(subscriber: subscriber, context: context)
            context.initializeContext(StartServiceHandler(task: task, delegate: delegate))
        }
    }
}
