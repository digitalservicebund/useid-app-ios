import Combine
import CombineSchedulers
import Foundation
import OpenEcard
import OSLog

extension OpenEcardImp: OpenEcardType {}

class IDInteractionManager: IDInteractionManagerType {
    
    private let openEcard: OpenEcardProtocol
    private var context: ContextManagerProtocol?
    private let issueTracker: IssueTracker
    
    init(openEcard: OpenEcardProtocol = OpenEcardImp(), issueTracker: IssueTracker) {
        self.openEcard = openEcard
        self.issueTracker = issueTracker
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
            .handleEvents(receiveCompletion: { [context, issueTracker] _ in
                startServiceHandler.cancel()
                context.terminateContext(StopServiceHandler(issueTracker: issueTracker))
            }, receiveCancel: { [context, issueTracker] in
                startServiceHandler.cancel()
                context.terminateContext(StopServiceHandler(issueTracker: issueTracker))
            }).eraseToAnyPublisher()
    }
}
