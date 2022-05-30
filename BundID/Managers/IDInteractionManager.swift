import Foundation
import Combine
import OpenEcard

class IDInteractionManager: IDInteractionManagerType {
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        let openEcard = OpenEcardImp()!
        guard let context = openEcard.context(NFSMessageProvider()) else {
            return Result.Publisher(.failure(.frameworkError(message: "Could not open context"))).eraseToAnyPublisher()
        }
        
        let delegate: OpenECardHandlerDelegate = OpenECardHandlerDelegate(context: context)
        context.initializeContext(StartServiceHandler(task: .eac(tokenURL: tokenURL), delegate: delegate))
        
        return delegate.publisher.eraseToAnyPublisher()
    }
    
    func changePIN() -> EIDInteractionPublisher {
        let openEcard = OpenEcardImp()!
        guard let context = openEcard.context(NFSMessageProvider()) else {
            return Result.Publisher(.failure(.frameworkError(message: "Could not open context"))).eraseToAnyPublisher()
        }
        let delegate: OpenECardHandlerDelegate = OpenECardHandlerDelegate(context: context)
        let handler = StartServiceHandler(task: .pinManagement, delegate: delegate)
        context.initializeContext(handler)
        
        return delegate.publisher.eraseToAnyPublisher()
    }
}
