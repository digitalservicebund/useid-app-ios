//
//  IDLoneosInteractionManager.swift
//  BundesIdent
//
//  Created by Andreas Ganske on 11.11.22.
//

import Foundation
import Combine

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

extension AA2UserInfoMessage {
    init(_ messages: ScanOverlayMessages) {
        self.init(
            sessionStarted: messages.sessionStarted,
            sessionFailed: messages.sessionFailed,
            sessionSucceeded: messages.sessionSucceeded,
            sessionInProgress: messages.sessionInProgress
        )
    }
}

// general InteractionWorkflow
class IDInteractionManager: WorkflowCallbacks {
    
    private let workflowController: AusweisApp2SDKWrapper.WorkflowController
    private let publisher: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>
    
    private var postponedWorkflow: Workflow?
    
    init(workflowController: AusweisApp2SDKWrapper.WorkflowController = AA2SDKWrapper.workflowController) {
        self.workflowController = workflowController
        publisher = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        
        workflowController.registerCallbacks(self)
        workflowController.start()
    }
    
    func publisher() -> EIDInteractionPublisher {
        publisher.handleEvents(receiveCancel: {
            print("Cancelling")
            self.workflowController.cancel()
            self.postponedWorkflow = nil
        }).eraseToAnyPublisher()
    }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) {
        let userInfoMessages = AA2UserInfoMessage(messages)
        guard workflowController.isStarted else {
            postponedWorkflow = Workflow.authentification(tokenURL: tokenURL,
                                                          developerMode: false,
                                                          userInfoMessages: userInfoMessages,
                                                          status: true)
            return
        }
        workflowController.startAuthentication(
            withTcTokenUrl: tokenURL,
            withDeveloperMode: false,
            withUserInfoMessages: userInfoMessages,
            withStatusMsgEnabled: true
        )
    }
    
    func changePIN(messages: ScanOverlayMessages) {
        let userInfoMessages = AA2UserInfoMessage(messages)
        guard workflowController.isStarted else {
            postponedWorkflow = Workflow.changePIN(userInfoMessages: userInfoMessages,
                                                   status: true)
            return
        }
        workflowController.startChangePin(
            withUserInfoMessages: userInfoMessages,
            withStatusMsgEnabled: true
        )
    }
    
    func onStarted() {
        defer { postponedWorkflow = nil }
        switch postponedWorkflow {
        case .none:
            return
        case .changePIN(userInfoMessages: let userInfoMessages, status: let status):
            workflowController.startChangePin(withUserInfoMessages: userInfoMessages,
                                              withStatusMsgEnabled: status)
        case .authentication(tcTokenURL: let tcTokenURL,
                             developerMode: let developerMode,
                             userInfoMessages: let userInfoMessages,
                             status: let status):
            workflowController.startAuthentication(
                withTcTokenUrl: tcTokenURL,
                withDeveloperMode: developerMode,
                withUserInfoMessages: userInfoMessages,
                withStatusMsgEnabled: status
            )
        }
    }
    
    func onChangePinStarted() {
        publisher.send(.pinChangeStarted)
    }
    
    func onAuthenticationStarted() {
        publisher.send(.authenticationStarted)
    }
    
    func onAuthenticationStartFailed(error: String) {
        publisher.send(completion: .failure(.frameworkError(message: "onAuthenticationStartFailed: \(error)")))
    }
    
    func onAccessRights(error: String?, accessRights: AccessRights?) {
        if let error {
            logger.error("onAccessRights error: \(error)")
        }
        
        guard let accessRights else {
            // TODO: Check when this happens
            logger.error("onAccessRights: Access rights missing.")
            publisher.send(completion: .failure(.frameworkError(message: "Access rights missing. Error: \(error)")))
            return
        }
        
        guard accessRights.requiredAccessRights == accessRights.effectiveAccessRights else {
            workflowController.setAccessRights([])
            return
        }
        
        let requiredRights = accessRights.requiredRights.map(IDCardAttribute.init)
        let request = AuthenticationRequest(requiredAttributes: requiredRights, transactionInfo: accessRights.transactionInfo)
        publisher.send(.authenticationRequestConfirmationRequested(request))
    }
    
    func onApiLevel(error: String?, apiLevel: ApiLevel?) {
        logger.warning("onApiLevel: \(error), \(apiLevel)")
    }
    
    func onInsertCard(error: String?) {
        if let error {
            // TODO: remove method names from logger
            logger.error("onInsertCard: \(error)")
        }
        publisher.send(.cardInsertionRequested)
    }
    
    func onAuthenticationCompleted(authResult: AusweisApp2SDKWrapper.AuthResult) {
        // TODO: check if result.major could be success
        if let errorResultData = authResult.result {
            // TODO: pass resultMajor up
            publisher.send(completion: .failure(.processFailed(redirectURL: errorResultData.url, resultMinor: errorResultData.resultMinor)))
        } else {
            publisher.send(.authenticationSucceeded(redirectUrl: url))
            publisher.send(completion: .finished)
        }
    }

    func onChangePinCompleted(changePinResult: AusweisApp2SDKWrapper.ChangePinResult?) {
        if changePinResult.success == true {
            publisher.send(.pinChangeSucceeded)
            publisher.send(completion: .finished)
        } else {
            publisher.send(completion: .failure(.pinChangeFailed))
        }
    }
    
    func onWrapperError(error: AusweisApp2SDKWrapper.WrapperError) {
        publisher.send(completion: .failure(.frameworkError(message: "onWrapperError: \(error.msg) - \(error.error)")))
    }
    
    func onBadState(error: String) {
        publisher.send(completion: .failure(.frameworkError(message: "onBadState: \(error)")))
    }
    
    func onCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        publisher.send(.certificateDescriptionRetrieved(.init(certificateDescription)))
    }

    func onEnterCan(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterCan error: \(error)")
        }
        publisher.send(.canRequested)
    }
    
    func onEnterNewPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterNewPin error: \(error)")
        }
        publisher.send(.newPINRequested)
    }
    
    func onEnterPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterPin error: \(error)")
        }
        publisher.send(.pinRequested(remainingAttempts: reader.card?.pinRetryCounter))
    }
    
    func onEnterPuk(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        if let error {
            logger.error("onEnterPuk error: \(error)")
        }
        publisher.send(.pukRequested)
    }
    
    func onInfo(versionInfo: AusweisApp2SDKWrapper.VersionInfo) {
        logger.info("onInfo: \(versionInfo)")
    }
    
    func onInternalError(error: String) {
        publisher.send(completion: .failure(.frameworkError(message: "onInternalError error: \(error)")))
    }
    
    func onReader(reader: AusweisApp2SDKWrapper.Reader?) {
        guard reader else {
            logger.error("onReader: Unknown reader")
            publisher.send(completion: .failure(.unknownReader))
            return
        }

        // TODO: Decide about cardRemoved being sent for initial state (before cardRecognized)
        // TODO: Sync with Android about usage of cardRecognized in general
        if let card = reader.card {
            publisher.send(.cardRecognized)
        } else {
            publisher.send(.cardRemoved)
        }
    }
    
    func onReaderList(readers: [AusweisApp2SDKWrapper.Reader]?) {
        logger.info("onReaderList: \(readers)")
    }
    
    func onStatus(workflowProgress: AusweisApp2SDKWrapper.WorkflowProgress) {
        logger.info("onStatus: \(workflowProgress)")
    }
    
    deinit {
        logger.error("Unexpected deinit")
        workflowController.stop()
    }
}
#endif
