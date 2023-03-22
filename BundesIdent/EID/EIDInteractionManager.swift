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

class EIDInteractionManager: EIDInteractionManagerType {

    private let workflowController: AusweisApp2SDKWrapper.WorkflowController
    private let logger: Logger
    private var currentFlowListener: EIDInteractionFlowListener?

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
            if let flowListener = currentFlowListener {
                workflowController.unregisterCallbacks(flowListener)
                currentFlowListener = nil
            }
        }

        let flowListener = EIDInteractionFlowListener(workflow: workflow, workflowController: workflowController)
        currentFlowListener = flowListener

        workflowController.registerCallbacks(flowListener)
        workflowController.start()
        
        let stopWorkflow = { [weak self] in
            guard let self else { return }
            self.workflowController.stop()
            self.workflowController.unregisterCallbacks(flowListener)
            self.currentFlowListener = nil
        }

        return flowListener.subject.handleEvents(receiveCompletion: { _ in stopWorkflow() }, receiveCancel: stopWorkflow).eraseToAnyPublisher()
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
