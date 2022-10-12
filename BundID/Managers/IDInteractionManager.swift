import Foundation
import Combine
import OpenEcard
import CombineSchedulers

extension OpenEcardImp: OpenEcardType {}

class IDInteractionManager: IDInteractionManagerType {
    
    private let openEcard: OpenEcardProtocol
    private var context: ContextManagerProtocol?
    
    init(openEcard: OpenEcardProtocol = OpenEcardImp()) {
        self.openEcard = openEcard
    }
    
    func identify(tokenURL: URL, nfcMessagesProvider: NFCConfigType) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .eac(tokenURL: tokenURL)), nfcMessagesProvider: nfcMessagesProvider)
    }
    
    func changePIN(nfcMessagesProvider: NFCConfigType) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .pinManagement), nfcMessagesProvider: nfcMessagesProvider)
    }
    
    private func start(startServiceHandler: StartServiceHandler, nfcMessagesProvider: NFCConfigType) -> EIDInteractionPublisher {
        let context = openEcard.context(nfcMessagesProvider)!
        context.initializeContext(startServiceHandler)
        self.context = context
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
