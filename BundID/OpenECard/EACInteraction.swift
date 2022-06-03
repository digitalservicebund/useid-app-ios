import Foundation
import Combine
import OpenEcard

class EACInteraction: NSObject, EACInteractionType {
    
    private let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
    
    var publisher: EIDInteractionPublisher { subject.eraseToAnyPublisher() }
    
    func onCanRequest(_ enterCan: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        subject.send(.requestCAN(enterCan.confirmPassword))
    }
    
    func onPinRequest(_ enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        onGeneralPINRequest(attempts: nil, enterPin: enterPin)
    }
    
    func onPinRequest(_ attempt: Int32, withEnterPin enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        onGeneralPINRequest(attempts: Int(attempt), enterPin: enterPin)
    }
    
    private func onGeneralPINRequest(attempts: Int?, enterPin: ConfirmPasswordOperationProtocol) {
        subject.send(.requestPIN(attempts: attempts, pinCallback: enterPin.confirmPassword))
    }
    
    func onPinCanRequest(_ enterPinCan: (NSObjectProtocol & ConfirmPinCanOperationProtocol)!) {
        subject.send(.requestPINAndCAN(enterPinCan.confirmPassword))
    }
    
    func onCardBlocked() {
        subject.send(completion: .failure(.cardBlocked))
    }
    
    func onCardDeactivated() {
        subject.send(completion: .failure(.cardDeactivated))
    }
    
    func onServerData(_ data: (NSObjectProtocol & ServerDataProtocol)!, withTransactionData transactionData: String!, withSelectReadWrite selectReadWrite: (NSObjectProtocol & ConfirmAttributeSelectionOperationProtocol)!) {
        let readAttributes: FlaggedAttributes
        do {
            readAttributes = try data.getReadAccessAttributes()!.mapToAttributeRequirements()
        } catch IDCardInteractionError.unexpectedReadAttribute(let attribute) {
            subject.send(completion: .failure(.unexpectedReadAttribute(attribute)))
            return
        } catch {
            subject.send(completion: .failure(.frameworkError(message: nil)))
            return
        }
        
        let eidServerData = EIDAuthenticationRequest(issuer: data.getIssuer(), issuerURL: data.getIssuerUrl(), subject: data.getSubject(), subjectURL: data.getSubjectUrl(), validity: data.getValidity(), terms: .text(data.getTermsOfUsage().getDataString()), readAttributes: readAttributes)
        
        let confirmationCallback: (FlaggedAttributes) -> Void = { selectReadWrite.enterAttributeSelection($0.selectableItemsSettingChecked, withWrite: []) }
        
        subject.send(.requestAuthenticationRequestConfirmation(eidServerData, confirmationCallback))
    }
    
    func onCardAuthenticationSuccessful() {
        subject.send(.authenticationSuccessful)
    }
    
    func requestCardInsertion() {
        subject.send(completion: .failure(.frameworkError(message: nil)))
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        subject.send(.requestCardInsertion(msgHandler.setText))
    }
    
    func onCardInteractionComplete() {
        subject.send(.cardInteractionComplete)
    }
    
    func onCardRecognized() {
        subject.send(.cardRecognized)
    }
    
    func onCardRemoved() {
        subject.send(.cardRemoved)
    }
}
