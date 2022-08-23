import Foundation
import Combine
import OpenEcard
import CombineSchedulers

typealias NFCConfigType = NSObjectProtocol & NFCConfigProtocol

extension OpenEcardImp: OpenEcardType {}

class IDInteractionManager: IDInteractionManagerType {
    
    private let openEcard: OpenEcardProtocol
    private var context: ContextManagerProtocol?
    
    init(openEcard: OpenEcardProtocol = OpenEcardImp()) {
        self.openEcard = openEcard
    }
    
    func identify(tokenURL: String, nfcMessages: NFCMessages = .identification) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .eac(tokenURL: tokenURL)),
              nfcMessages: nfcMessages)
    }
    
    func changePIN(nfcMessages: NFCMessages = NFCMessages.setup) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .pinManagement),
              nfcMessages: nfcMessages)
    }
    
    private func start(startServiceHandler: StartServiceHandler, nfcMessages: NFCMessages) -> EIDInteractionPublisher {
        let nfcMessageProvider = NFCMessageProvider(nfcMessages: nfcMessages)
        let context = openEcard.context(nfcMessageProvider)!
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
