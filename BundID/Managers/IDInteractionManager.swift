import Foundation
import Combine
import OpenEcard

class IDInteractionManager: IDInteractionManagerType {
    
    let openEcard: OpenEcardImp
    let context: ContextManagerProtocol
    
    init() {
        openEcard = OpenEcardImp()!
        context = openEcard.context(NFCMessageProvider())!
    }
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .eac(tokenURL: tokenURL)))
    }
    
    func changePIN() -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .pinManagement))
    }
    
    private func start(startServiceHandler: StartServiceHandler) -> EIDInteractionPublisher {
        context.initializeContext(startServiceHandler)
        return startServiceHandler.publisher
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { [weak self] _ in
                startServiceHandler.cancel()
                self?.context.terminateContext(StopServiceHandler())
            }, receiveCancel: { [weak self] in
                startServiceHandler.cancel()
                self?.context.terminateContext(StopServiceHandler())
            }).eraseToAnyPublisher()
    }
}
