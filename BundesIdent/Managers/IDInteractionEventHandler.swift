import Foundation
import Combine
import OSLog

#if !targetEnvironment(simulator)
import AusweisApp2SDKWrapper

final class IDInteractionEventHandler: WorkflowCallbacks {
    
    let subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>

    private let workflow: Workflow
    private let workflowController: AusweisApp2SDKWrapper.WorkflowController
    private let logger: Logger

    init(workflow: Workflow, workflowController: AusweisApp2SDKWrapper.WorkflowController) {
        self.workflow = workflow
        self.workflowController = workflowController
        logger = Logger(category: String(describing: Self.self))
        subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
    }

    func onStarted() {
        switch workflow {
        case .changePIN(userInfoMessages: let userInfoMessages, status: let status):
            workflowController.startChangePin(withUserInfoMessages: userInfoMessages,
                                              withStatusMsgEnabled: status)
        case .authentification(tcTokenUrl: let tcTokenUrl,
                               developerMode: let developerMode,
                               userInfoMessages: let userInfoMessages,
                               status: let status):
            workflowController.startAuthentication(
                withTcTokenUrl: tcTokenUrl,
                withDeveloperMode: developerMode,
                withUserInfoMessages: userInfoMessages,
                withStatusMsgEnabled: status
            )
        }
    }

    func onChangePinStarted() {
        subject.send(.pinChangeStarted)
    }

    func onAuthenticationStarted() {
        subject.send(.authenticationStarted)
    }

    func onAuthenticationStartFailed(error: String) {
        subject.send(completion: .failure(.frameworkError(message: "onAuthenticationStartFailed: \(error)")))
    }

    func onAccessRights(error: String?, accessRights: AccessRights?) {
        if let error {
            logger.error("onAccessRights error: \(error)")
        }

        guard let accessRights else {
            // TODO: Check when this happens
            logger.error("onAccessRights: Access rights missing.")
            subject.send(completion: .failure(.frameworkError(message: "Access rights missing. Error: \(error)")))
            return
        }

        guard accessRights.requiredRights == accessRights.effectiveRights else {
            workflowController.setAccessRights([])
            return
        }

        let requiredRights = accessRights.requiredRights.map(IDCardAttribute.init)
        let request = AuthenticationRequest(requiredAttributes: requiredRights, transactionInfo: accessRights.transactionInfo)
        subject.send(.authenticationRequestConfirmationRequested(request))
    }

    func onApiLevel(error: String?, apiLevel: ApiLevel?) {
        logger.warning("onApiLevel: \(String(describing: error)), \(String(describing: apiLevel))")
    }

    func onInsertCard(error: String?) {
        if let error {
            // TODO: Remove duplicated method names from logger
            logger.error("onInsertCard: \(String(describing: error))")
        }
        subject.send(.cardInsertionRequested)
    }

    func onAuthenticationCompleted(authResult: AusweisApp2SDKWrapper.AuthResult) {
        // TODO: Check if result.major could be success. Answer: Yes, it is.
        // TODO: We need to check against resultmajor#ok, which should be implemented better than a check against a hardcoded string
        if let errorResultData = authResult.result, errorResultData.major != "http://www.bsi.bund.de/ecard/api/1.1/resultmajor#ok" {
            // TODO: Pass result.major up
            subject.send(completion: .failure(.processFailed(resultCode: .CLIENT_ERROR, redirectURL: authResult.url, resultMinor: errorResultData.minor)))
        } else {
            subject.send(.authenticationSucceeded(redirectUrl: authResult.url))
            subject.send(completion: .finished)
        }
    }

    func onChangePinCompleted(changePinResult: AusweisApp2SDKWrapper.ChangePinResult?) {
        if changePinResult?.success == true {
            subject.send(.pinChangeSucceeded)
            subject.send(completion: .finished)
        } else {
            subject.send(completion: .failure(.pinChangeFailed))
        }
    }

    func onWrapperError(error: AusweisApp2SDKWrapper.WrapperError) {
        subject.send(completion: .failure(.frameworkError(message: "onWrapperError: \(error.msg) - \(error.error)")))
    }

    func onBadState(error: String) {
        // TODO: issueTracker instead
        subject.send(completion: .failure(.frameworkError(message: "onBadState: \(error)")))
    }

    func onCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        subject.send(.certificateDescriptionRetrieved(.init(certificateDescription)))
    }

    func onEnterCan(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterCan error: \(error)")
        }
        subject.send(.canRequested)
    }

    func onEnterNewPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterNewPin error: \(error)")
        }
        subject.send(.newPINRequested)
    }

    func onEnterPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterPin error: \(error)")
        }
        subject.send(.pinRequested(remainingAttempts: reader.card?.pinRetryCounter))
    }

    func onEnterPuk(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterPuk error: \(error)")
        }
        subject.send(.pukRequested)
    }

    func onInfo(versionInfo: AusweisApp2SDKWrapper.VersionInfo) {
        logger.info("onInfo: \(String(describing: versionInfo))")
    }

    func onInternalError(error: String) {
        subject.send(completion: .failure(.frameworkError(message: "onInternalError error: \(error)")))
    }

    func onReader(reader: AusweisApp2SDKWrapper.Reader?) {
        guard let reader else {
            logger.error("onReader: Unknown reader")
            // reader is nil when authentication is done
            // subject.send(completion: .failure(.unknownReader))
            return
        }

        // TODO: Decide about cardRemoved being sent for initial state (before cardRecognized)
        if let card = reader.card {
            // TODO: What do we do when the card is deactivated (meaning the online ausweisfunktion is not activated)
            // Is this event the only info about that? How to tell the application?
            if card.deactivated {
                subject.send(completion: .failure(.cardDeactivated))
            } else {
                subject.send(.cardRecognized)
            }
        } else {
            subject.send(.cardRemoved)
        }
    }

    func onReaderList(readers: [AusweisApp2SDKWrapper.Reader]?) {
        logger.info("onReaderList: \(String(describing: readers))")
    }

    func onStatus(workflowProgress: AusweisApp2SDKWrapper.WorkflowProgress) {
        logger.info("onStatus: \(String(describing: workflowProgress))")
    }
}

#endif
