import Foundation
import Combine
import OpenEcard
import CombineSchedulers

typealias NFCConfigType = NSObjectProtocol & NFCConfigProtocol

extension OpenEcardImp: OpenEcardType {}

class IDInteractionManager: IDInteractionManagerType {
    
    private let openEcard: OpenEcardProtocol
    private let context: ContextManagerProtocol
    
    init(openEcard: OpenEcardProtocol = OpenEcardImp(), nfcMessageProvider: NFCConfigType = NFCMessageProvider()) {
        self.openEcard = openEcard
        self.context = openEcard.context(nfcMessageProvider)
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
            .handleEvents(receiveCompletion: { [context] _ in
                startServiceHandler.cancel()
                context.terminateContext(StopServiceHandler())
            }, receiveCancel: { [context] in
                startServiceHandler.cancel()
                context.terminateContext(StopServiceHandler())
            }).eraseToAnyPublisher()
    }
}
