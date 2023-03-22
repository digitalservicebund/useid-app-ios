import Foundation
import Combine
import OpenEcard
import CombineSchedulers
import OSLog
import AusweisApp2SDKWrapper

extension OpenEcardImp: OpenEcardType {}

class IDInteractionManager: IDInteractionManagerType {
    
    private let issueTracker: IssueTracker
    
    private let workflowController: WorkflowController
    
    init(workflowController: WorkflowController = AA2SDKWrapper.workflowController, issueTracker: IssueTracker) {
        self.issueTracker = issueTracker
        self.workflowController = workflowController
    }
    
    func identify(tokenURL: URL, nfcMessagesProvider: NFCConfigType) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .eac(tokenURL: tokenURL)), nfcMessagesProvider: nfcMessagesProvider)
    }
    
    func changePIN(nfcMessagesProvider: NFCConfigType) -> EIDInteractionPublisher {
        start(startServiceHandler: StartServiceHandler(task: .pinManagement), nfcMessagesProvider: nfcMessagesProvider)
    }
    
    private func start(startServiceHandler: StartServiceHandler, nfcMessagesProvider: NFCConfigType) -> EIDInteractionPublisher {
        let publisher = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        workflowController.start()
        return publisher.eraseToAnyPublisher()
    }
}
