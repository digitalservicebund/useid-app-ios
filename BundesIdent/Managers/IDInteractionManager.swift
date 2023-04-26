import Foundation
import Combine
import OSLog

typealias EIDInteractionPublisher = AnyPublisher<EIDInteractionEvent, EIDInteractionError>
typealias FlaggedAttributes = [EIDAttribute: Bool]

#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper

enum Workflow {
    case changePIN(userInfoMessages: AA2UserInfoMessages?, status: Bool)
    case authentification(tcTokenUrl: URL, developerMode: Bool, userInfoMessages: AA2UserInfoMessages?, status: Bool)
}

extension AusweisApp2SDKWrapper.AA2UserInfoMessages {
    init(_ messages: ScanOverlayMessages) {
        self.init(
            sessionStarted: messages.sessionStarted,
            sessionFailed: messages.sessionFailed,
            sessionSucceeded: messages.sessionSucceeded,
            sessionInProgress: messages.sessionInProgress
        )
    }
}

class IDInteractionManager: IDInteractionManagerType {

    private let workflowController: AusweisApp2SDKWrapper.WorkflowController
    private let logger: Logger
    private var currentHandler: IDInteractionEventHandler?

    init(workflowController: AusweisApp2SDKWrapper.WorkflowController = AA2SDKWrapper.workflowController) {
        self.workflowController = workflowController
        logger = Logger(category: String(describing: Self.self))
    }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        start(workflow: .authentification(tcTokenUrl: tokenURL,
                                          developerMode: false,
                                          userInfoMessages: AA2UserInfoMessages(messages),
                                          status: true))
    }
    
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        start(workflow: .changePIN(userInfoMessages: .init(messages), status: true))
    }

    private func start(workflow: Workflow) -> EIDInteractionPublisher {
        if workflowController.isStarted {
            logger.error("Starting the flow while it was already started.")
            workflowController.stop()
            if let handler = currentHandler {
                workflowController.unregisterCallbacks(handler)
                currentHandler = nil
            }
        }

        let handler = IDInteractionEventHandler(workflow: workflow, workflowController: workflowController)
        currentHandler = handler

        workflowController.registerCallbacks(handler)
        workflowController.start()
        
        let stopWorkflow = { [weak self] in
            guard let self else { return }
            self.workflowController.stop()
            self.workflowController.unregisterCallbacks(handler)
            self.currentHandler = nil
        }

        return handler.subject.handleEvents(receiveCompletion: { _ in stopWorkflow() }, receiveCancel: stopWorkflow).eraseToAnyPublisher()
    }

    func setPIN(_ pin: String) {
        workflowController.setPin(pin)
    }

    func setNewPIN(_ pin: String) {
        workflowController.setNewPin(pin)
    }

    func setCAN(_ can: String) {
        workflowController.setCan(can)
    }
    
    func retrieveCertificateDescription() {
        workflowController.getCertificate()
    }
    
    func acceptAccessRights() {
        workflowController.accept()
    }
    
    func interrupt() {
        workflowController.interrupt()
    }
}
#endif
