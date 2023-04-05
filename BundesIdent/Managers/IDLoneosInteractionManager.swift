import Foundation
import Combine
import OSLog

#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper

extension AusweisApp2SDKWrapper.AuxiliaryData: Equatable {
    public static func == (lhs: AuxiliaryData, rhs: AuxiliaryData) -> Bool {
        lhs.ageVerificationDate == rhs.ageVerificationDate &&
            lhs.communityId == rhs.communityId &&
            lhs.requiredAge == rhs.requiredAge &&
            lhs.validityDate == rhs.validityDate
    }
}

extension AusweisApp2SDKWrapper.AccessRights: Equatable {
    public static func == (lhs: AusweisApp2SDKWrapper.AccessRights, rhs: AusweisApp2SDKWrapper.AccessRights) -> Bool {
        lhs.effectiveRights == rhs.effectiveRights &&
            lhs.requiredRights == rhs.requiredRights &&
            lhs.optionalRights == rhs.optionalRights &&
            lhs.transactionInfo == rhs.transactionInfo &&
            lhs.auxiliaryData == rhs.auxiliaryData
    }
}

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

    init(workflowController: AusweisApp2SDKWrapper.WorkflowController = AA2SDKWrapper.workflowController) {
        self.workflowController = workflowController
        logger = Logger(category: String(describing: Self.self))
    }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        guard !workflowController.isStarted else {
            logger.error("Tried to identify when workflow is started.")
            // TODO: Throw error
            fatalError()
        }

        let workflow = Workflow.authentification(tcTokenUrl: tokenURL,
                                                 developerMode: false,
                                                 userInfoMessages: AA2UserInfoMessages(messages),
                                                 status: true)
        let handler = IDInteractionEventHandler(workflow: workflow, workflowController: workflowController)

        // TODO: Unregister when stopping
        workflowController.registerCallbacks(handler)
        workflowController.start()
        return handler.publisher
    }
    
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        guard !workflowController.isStarted else {
            logger.error("Tried to change PIN when workflow is started.")
            // TODO: Throw error
            fatalError()
        }

        let workflow = Workflow.changePIN(userInfoMessages: .init(messages), status: true)
        let handler = IDInteractionEventHandler(workflow: workflow, workflowController: workflowController)

        // TODO: Unregister when stopping
        workflowController.registerCallbacks(handler)
        workflowController.start()
        return handler.publisher
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
    
    func cancel() {
        workflowController.cancel()
    }
    
    deinit {
        logger.error("Unexpected deinit")
        workflowController.stop()
    }
}
#endif
