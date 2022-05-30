import Foundation
import Combine
import OpenEcard

class EACInteraction: OpenECardHandlerBase, EacInteractionProtocol {
    func onCanRequest(_ enterCan: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        delegate.send(event: .requestCAN(enterCan.confirmPassword))
    }
    
    func onPinRequest(_ enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        onGeneralPINRequest(attempts: nil, enterPin: enterPin)
    }
    
    func onPinRequest(_ attempt: Int32, withEnterPin enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        onGeneralPINRequest(attempts: Int(attempt), enterPin: enterPin)
    }
    
    private func onGeneralPINRequest(attempts: Int?, enterPin: ConfirmPasswordOperationProtocol) {
        delegate.send(event: .requestPIN(attempts: attempts, pinCallback: enterPin.confirmPassword))
    }
    
    func onPinCanRequest(_ enterPinCan: (NSObjectProtocol & ConfirmPinCanOperationProtocol)!) {
        delegate.send(event: .requestPINAndCAN(enterPinCan.confirmPassword))
    }
    
    func onCardBlocked() {
        delegate.fail(error: .cardBlocked)
    }
    
    func onCardDeactivated() {
        delegate.fail(error: .cardDeactivated)
    }
    
    func onServerData(_ data: (NSObjectProtocol & ServerDataProtocol)!, withTransactionData transactionData: String!, withSelectReadWrite selectReadWrite: (NSObjectProtocol & ConfirmAttributeSelectionOperationProtocol)!) {
        let readAttributes: FlaggedAttributes
        do {
            readAttributes = try data.getReadAccessAttributes()!.mapToAttributeRequirements()
        } catch IDCardInteractionError.unexpectedReadAttribute(let attribute) {
            delegate.fail(error: IDCardInteractionError.unexpectedReadAttribute(attribute))
            return
        } catch {
            delegate.fail(error: .frameworkError(message: nil))
            return
        }
        
        let eidServerData = EIDAuthenticationRequest(issuer: data.getIssuer(), issuerURL: data.getIssuerUrl(), subject: data.getSubject(), subjectURL: data.getSubjectUrl(), validity: data.getValidity(), terms: .text(data.getTermsOfUsage().getDataString()), readAttributes: readAttributes)
        
        let confirmationCallback: (FlaggedAttributes) -> Void = { selectReadWrite.enterAttributeSelection($0.selectableItemsSettingChecked, withWrite: []) }
        
        delegate.send(event: .requestAuthenticationRequestConfirmation(eidServerData, confirmationCallback))
    }
    
    func onCardAuthenticationSuccessful() {
        delegate.send(event: .authenticationSuccessful)
    }
    
    func requestCardInsertion() {
        delegate.fail(error: .frameworkError(message: nil))
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        delegate.send(event: .requestCardInsertion(msgHandler.setText))
    }
    
    func onCardInteractionComplete() {
        delegate.send(event: .cardInteractionComplete)
    }
    
    func onCardRecognized() {
        delegate.send(event: .cardRecognized)
    }
    
    func onCardRemoved() {
        delegate.send(event: .cardRemoved)
    }
}
