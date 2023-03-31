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

struct AuthenticationRequest {
    var requiredAttributes: [IDCardAttribute]
    var transactionInfo: String?
}

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

class SetupPINInteractionWorkflow: WorkflowCallbacks {
    
    private let workflowController: AusweisApp2SDKWrapper.WorkflowController
    private let publisher: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>
    
    init(workflowController: AusweisApp2SDKWrapper.WorkflowController = AA2SDKWrapper.workflowController) {
        self.workflowController = workflowController
        publisher = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        
        workflowController.registerCallbacks(self)
        workflowController.start()
    }
    
    func changePIN() -> EIDInteractionPublisher {
        publisher.handleEvents(receiveCompletion: { _ in
            self.workflowController.stop()
        }, receiveCancel: {
            print("Cancelling")
            self.workflowController.cancel()
        }).eraseToAnyPublisher()
    }
    
    func onStarted() {
        workflowController.startChangePin(
            withUserInfoMessages: AA2UserInfoMessages(sessionStarted: "sessionStarted",
                                                      sessionFailed: "sessionFailed",
                                                      sessionSucceeded: "sessionSucceeded",
                                                      sessionInProgress: "sessionInProgress"))
    }
    
    func onChangePinStarted() {
        publisher.send(.pinManagementStarted)
    }
    
    func onAuthenticationStarted() {
        publisher.send(.authenticationStarted)
    }
    
    func onAuthenticationStartFailed(error: String) {
        publisher.send(completion: .failure(.frameworkError(message: error)))
    }
    
    func onPinChangeStarted() {
        publisher.send(.pinManagementStarted)
    }
    
    func onRequestAccessRights(accessRights: AusweisApp2SDKWrapper.AccessRights) {
        // TODO: Unexpected event
        print("onRequestAccessRights: \(accessRights)")
    }
    
    func onReceivedCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        // TODO: Unexpected event
        print("onReceivedCertificate: \(certificateDescription)")
    }
    
    func onAccessRights(error: String?, accessRights: AccessRights?) {
        // TODO: Unexpected event, as we never set access rights
        if let error {
            logger.error("onAccessRights error: \(error)")
        }
        
        guard let accessRights else {
            logger.error("Access rights missing. Error: \(error)")
            publisher.send(completion: .failure(.frameworkError(message: "Access rights missing. Error: \(error)")))
            return
        }
        
        guard accessRights.requiredAccessRights == accessRights.effectiveAccessRights else {
            workflowController.setAccesRights([])
            return
        }
        
        let requiredRights = accessRights.requiredRights
        let request = AuthenticationRequest(requiredAttributes: requiredRights, transactionInfo: accessRights.transactionInfo)
        publisher.send(.requestAuthenticationRequestConfirmation(request))
    }
    
    func onApiLevel(error: String?, apiLevel: ApiLevel?) {
        // TODO: Unexpected event
        print("onApiLevel: \(error), \(apiLevel)")
    }
    
    //    func onRequestAccessRights(accessRights: IDLoneos.AccessRights) {
    ////        guard let certificateDescription = certificateDescription else { return } // TODO: Use instead of EIDAuthenticationRequest.preview
    //        publisher.send(.requestAuthenticationRequestConfirmation(EIDAuthenticationRequest.preview, { [workflowController] acceptedRights in
    //            // TODO: Remove all optional rights
    //            workflowController.accept()
    //        }))
    //    }
    //
    //    func onReceivedCertificate(certificateDescription: IDLoneos.CertificateDescription) {
    //        self.certificateDescription = certificateDescription
    //    }
    
    func onInsertCard(error: String?) {
        print("onInsertCard: \(error)")
        if let error {
            // this should not happen, so we just log it here instead of bailing out
            logger.error(error)
        }
        publisher.send(.requestCardInsertion)
    }
    
    func onAuthenticationCompleted(authResult: AusweisApp2SDKWrapper.AuthResult) {
        // TODO: check if result.major could be success
        if let errorResultData = authResult.result {
            publisher.send(completion: .failure(.processFailed(redirectURL: errorResultData.url, resultMinor: errorResultData.resultMinor)))
        } else {
            if let url = authResult.url {
                publisher.send(.processCompletedSuccessfullyWithRedirect(url: url))
            } else {
                publisher.send(.processCompletedSuccessfullyWithoutRedirect)
            }
        }
        print("onAuthenticationCompleted: \(authResult)")
        // TODO: Unexpected event
//        if let error = authResult.error {
//            publisher.send(completion: .failure(.frameworkError(message: error.message)))
//            publisher.send(completion: .finished)
//            return
//        }
//
//        publisher.send(.authenticationSuccessful)
//        if let url = authResult.url {
//            publisher.send(.processCompletedSuccessfullyWithRedirect(url: url))
//        } else {
//            publisher.send(.processCompletedSuccessfullyWithoutRedirect)
//        }
//        publisher.send(completion: .finished)
    }
    
    func onChangePinCompleted(changePinResult: AusweisApp2SDKWrapper.ChangePinResult?) {
        print("onChangePinCompleted: \(changePinResult)")
        publisher.send(.processCompletedSuccessfullyWithoutRedirect)
        publisher.send(completion: .finished)
    }
    
    func onWrapperError(error: AusweisApp2SDKWrapper.WrapperError) {
        print("onWrapperError: \(error)")
        publisher.send(completion: .failure(.frameworkError(message: "onWrapperError: \(error.msg) - \(error.error)"))) // Yes
    }
    
    func onBadState(error: String) {
        print("onBadState")
        publisher.send(completion: .failure(.frameworkError(message: "onBadState: \(error)")))
    }
    
    func onCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        print("onCertificate: \(certificateDescription)")
        publisher.send(.authenticationCertificate(CertificateDescription()))
    }
    
    func onEnterCan(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterCan: \(error), reader: \(reader)")
        workflowController.interrupt()
        publisher.send(.requestCANAndChangedPIN(pinCallback: { [workflowController] oldPIN, can, newPIN in
            workflowController.setCan(can)
        }))
    }
    
    func onEnterNewPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterNewPin: \(error), reader: \(reader)")
        publisher.send(.requestChangedPIN(remainingAttempts: reader.card?.pinRetryCounter, pinCallback: { [workflowController] oldPIN, newPIN in
            workflowController.setNewPin(newPIN)
        }))
    }
    
    func onEnterPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterPin: \(error), reader: \(reader)")
        publisher.send(.requestPIN(remainingAttempts: reader.card?.pinRetryCounter))
    }
    
    func onEnterPuk(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterPuk: \(error), reader: \(reader)")
        publisher.send(.requestPUK)
    }
    
    func onInfo(versionInfo: AusweisApp2SDKWrapper.VersionInfo) {
        print("onInfo: \(versionInfo)")
    }
    
    func onInternalError(error: String) {
        print("onInternalError: \(error)")
        publisher.send(completion: .failure(.frameworkError(message: error)))
    }
    
    func onReader(reader: AusweisApp2SDKWrapper.Reader?) {
        // TODO: Unexpected, we do not handle readers?
        print("onReader: \(reader)")
//        if reader?.card == nil {
//            publisher.send(completion: .failure(.frameworkError(message: "Unknown card")))
//        }
        guard reader else {
            logger.error("Unknown reader")
            publisher.send(completion: .failure(.unknownReader))
            return
        }
        
        if let card = reader.card {
            publisher.send(.cardRemoved)
        } else {
            publisher.send(.cardRecognized)
        }
    }
    
    func onReaderList(readers: [AusweisApp2SDKWrapper.Reader]?) {
        // TODO: Unexpected, we do not handle readers?
        print("onReaderList: \(readers)")
    }
    
    func onStatus(workflowProgress: AusweisApp2SDKWrapper.WorkflowProgress) {
        logger.info("onStatus: \(workflowProgress, .privacy: .none)")
    }
    
    deinit {
        print("DEINIT should only be called when scanning done")
        workflowController.stop()
    }
}
#endif
