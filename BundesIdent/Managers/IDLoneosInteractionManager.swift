//
//  IDLoneosInteractionManager.swift
//  BundesIdent
//
//  Created by Andreas Ganske on 11.11.22.
//

import Foundation
import AusweisApp2SDKWrapper
import Combine

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

enum IDLoneosInteractionEvent: Equatable {
    case requestCardInsertion((String) -> Void)
    case cardInteractionComplete
    case cardRecognized
    case cardRemoved
    case requestCAN((_ can: String) -> Void)
    case requestOldPIN(pinCallback: (_ oldPin: String) -> Void)
    case requestNewPIN(remainingAttempts: Int, pinCallback: (_ newPin: String) -> Void)
    case requestPUK((_ puk: String) -> Void)
    case processCompletedSuccessfullyWithoutRedirect
    case processCompletedSuccessfullyWithRedirect(url: URL)
    case processFailedWithRedirect(url: URL)
    case processFailedWithoutRedirect
    case authenticationStarted
    case requestAuthenticationRequestConfirmation(AusweisApp2SDKWrapper.AccessRights, (FlaggedAttributes) -> Void)
    case authenticationSuccessful
    case pinManagementStarted
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.requestCardInsertion, .requestCardInsertion): return true
        case (.cardInteractionComplete, .cardInteractionComplete): return true
        case (.cardRecognized, .cardRecognized): return true
        case (.cardRemoved, .cardRemoved): return true
        case (.requestCAN, .requestCAN): return true
        case (.requestOldPIN, .requestOldPIN): return true
        case (.requestNewPIN(let lhsAttempts, _), .requestNewPIN(let rhsAttempts, _)):
            return lhsAttempts == rhsAttempts
        case (.requestPUK, .requestPUK): return true
        case (.processCompletedSuccessfullyWithoutRedirect, .processCompletedSuccessfullyWithoutRedirect): return true
        case (.processCompletedSuccessfullyWithRedirect(let lhsURL), .processCompletedSuccessfullyWithRedirect(let rhsURL)):
            return lhsURL == rhsURL
        case (.authenticationStarted, .authenticationStarted): return true
        case (.requestAuthenticationRequestConfirmation(let lhsRequest, _), .requestAuthenticationRequestConfirmation(let rhsRequest, _)): return lhsRequest == rhsRequest
        case (.authenticationSuccessful, .authenticationSuccessful): return true
        case (.pinManagementStarted, .pinManagementStarted): return true
        default: return false
        }
    }
}

typealias IDLoneosInteractionPublisher = AnyPublisher<IDLoneosInteractionEvent, IDCardInteractionError>

class SetupPINInteractionWorkflow: WorkflowCallbacks {
    
    private let workflowController: AusweisApp2SDKWrapper.WorkflowController
    private let publisher: PassthroughSubject<IDLoneosInteractionEvent, IDCardInteractionError>
    
    init(workflowController: AusweisApp2SDKWrapper.WorkflowController = AA2SDKWrapper.workflowController) {
        self.workflowController = workflowController
        publisher = PassthroughSubject<IDLoneosInteractionEvent, IDCardInteractionError>()
        
        workflowController.registerCallbacks(self)
        workflowController.start()
    }
    
    func changePIN() -> IDLoneosInteractionPublisher {
        publisher.handleEvents(receiveCompletion: { _ in
            self.workflowController.stop()
        }, receiveCancel: {
            print("Cancelling")
            self.workflowController.cancel()
        }).eraseToAnyPublisher()
    }
    
    func onStarted() {
        // TODO: What should we do here?
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
    }
    
    func onReceivedCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        // TODO: Unexpected event
    }
    
    func onAccessRights(error: String?, accessRights: AccessRights?) {
        // TODO: Unexpected event
        guard let accessRights else {
            // trigger error
            return
        }
        publisher.send(.requestAuthenticationRequestConfirmation(accessRights, { [workflowController] _ in
            workflowController.accept()
        }))
    }
    
    func onApiLevel(error: String?, apiLevel: ApiLevel?) {
        // TODO: Unexpected event
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
        if let error {
            publisher.send(completion: .failure(.frameworkError(message: error)))
            return
        }
    }
    
    func onRequestPin(card: AusweisApp2SDKWrapper.Card) {
        // TODO: If we are in the change pin flow, we need to send the requestChangedPIN callback
        publisher.send(.requestOldPIN(pinCallback: { [workflowController] pin in
            workflowController.setPin(pin)
        }))
    }
    
    func onRequestNewPin(card: AusweisApp2SDKWrapper.Card) {
        publisher.send(.requestNewPIN(remainingAttempts: card.pinRetryCounter, pinCallback: { [workflowController] newPIN in
            workflowController.setNewPin(newPIN)
        }))
    }
    
    func onRequestPuk(card: AusweisApp2SDKWrapper.Card) {
        publisher.send(.requestPUK({ [workflowController] puk in
            workflowController.setPuk(puk)
        }))
    }
    
    func onRequestCan(card: AusweisApp2SDKWrapper.Card) {
        publisher.send(.requestCAN({ [workflowController] can in
            workflowController.setCan(can)
        }))
    }
    
    func onAuthenticationCompleted(authResult: AusweisApp2SDKWrapper.AuthResult) {
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
        publisher.send(.processCompletedSuccessfullyWithoutRedirect)
        publisher.send(completion: .finished)
    }
    
    func onWrapperError(error: AusweisApp2SDKWrapper.WrapperError) {
        publisher.send(completion: .failure(.frameworkError(message: "\(error.msg) - \(error.error)")))
    }
    
    func onBadState(error: String) {
        print("onBadState")
    }
    
    func onCertificate(certificateDescription: AusweisApp2SDKWrapper.CertificateDescription) {
        print("onCertificate: \(certificateDescription)")
    }
    
    func onEnterCan(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterCan: \(error), reader: \(reader)")
    }
    
    func onEnterNewPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterNewPin: \(error), reader: \(reader)")
    }
    
    func onEnterPin(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterPin: \(error), reader: \(reader)")
    }
    
    func onEnterPuk(error: String?, reader: AusweisApp2SDKWrapper.Reader) {
        print("onEnterPuk: \(error), reader: \(reader)")
    }
    
    func onInfo(versionInfo: AusweisApp2SDKWrapper.VersionInfo) {
        print("onInfo: \(versionInfo)")
    }
    
    func onInternalError(error: String) {
        publisher.send(completion: .failure(.frameworkError(message: error)))
    }
    
    func onReader(reader: AusweisApp2SDKWrapper.Reader?) {
        // TODO: Unexpected, we do not handle readers?
    }
    
    func onReaderList(readers: [AusweisApp2SDKWrapper.Reader]?) {
        // TODO: Unexpected, we do not handle readers?
    }
    
    func onStatus(workflowProgress: AusweisApp2SDKWrapper.WorkflowProgress) {
        print("onStatus: \(workflowProgress)")
    }
    
    deinit {
        workflowController.stop()
    }
}
