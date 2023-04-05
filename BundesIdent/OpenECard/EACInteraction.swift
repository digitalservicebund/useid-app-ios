//import Foundation
//import Combine
//import OpenEcard
//
//class EACInteraction: NSObject, EACInteractionType {
//    
//    private let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
//    
//    var publisher: EIDInteractionPublisher { subject.eraseToAnyPublisher() }
//    
//    func onCanRequest(_ enterCan: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
//        subject.send(.requestCAN(enterCan.confirmPassword))
//    }
//    
//    func onPinRequest(_ enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
//        onGeneralPINRequest(remainingAttempts: nil, enterPin: enterPin)
//    }
//    
//    func onPinRequest(_ attempt: Int32, withEnterPin enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
//        onGeneralPINRequest(remainingAttempts: Int(attempt), enterPin: enterPin)
//    }
//    
//    private func onGeneralPINRequest(remainingAttempts: Int?, enterPin: ConfirmPasswordOperationProtocol) {
//        subject.send(.requestPIN(remainingAttempts: remainingAttempts, pinCallback: enterPin.confirmPassword))
//    }
//    
//    func onPinCanRequest(_ enterPinCan: (NSObjectProtocol & ConfirmPinCanOperationProtocol)!) {
//        subject.send(.requestPINAndCAN(enterPinCan.confirmPassword))
//    }
//    
//    func onCardBlocked() {
//        subject.send(completion: .failure(.cardBlocked))
//    }
//    
//    func onCardDeactivated() {
//        subject.send(completion: .failure(.cardDeactivated))
//    }
//    
//    func onServerData(_ data: (NSObjectProtocol & ServerDataProtocol)!, withTransactionData transactionData: String!, withSelectReadWrite selectReadWrite: (NSObjectProtocol & ConfirmAttributeSelectionOperationProtocol)!) {
//        do {
//            let readAccessAttributes = data.getReadAccessAttributes()!
//            let flaggedAttributes = try readAccessAttributes.mapToAttributeRequirements()
//            
//            let eidServerData = EIDAuthenticationRequest(
//                issuer: data.getIssuer(),
//                issuerURL: data.getIssuerUrl(),
//                subject: data.getSubject(),
//                subjectURL: data.getSubjectUrl(),
//                validity: data.getValidity(),
//                terms: .text(data.getTermsOfUsage().getDataString()),
//                transactionInfo: transactionData,
//                readAttributes: flaggedAttributes
//            )
//            
//            let confirmationCallback: (FlaggedAttributes) -> Void = { attributes in
//                readAccessAttributes.forEach { attribute in
//                    if let checked = attributes[IDCardAttribute(rawValue: attribute.getName()!)!] {
//                        attribute.setChecked(checked)
//                    }
//                }
//                selectReadWrite.enterAttributeSelection(readAccessAttributes, withWrite: [])
//            }
//            
//            subject.send(.requestAuthenticationRequestConfirmation(eidServerData, confirmationCallback))
//        } catch IDCardInteractionError.unexpectedReadAttribute(let attribute) {
//            subject.send(completion: .failure(.unexpectedReadAttribute(attribute)))
//            return
//        } catch {
//            subject.send(completion: .failure(.frameworkError(message: nil)))
//            return
//        }
//    }
//    
//    func onCardAuthenticationSuccessful() {
//        subject.send(.authenticationSuccessful)
//    }
//    
//    func requestCardInsertion() {
//        subject.send(completion: .failure(.frameworkError(message: nil)))
//    }
//    
//    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
//        subject.send(.requestCardInsertion(msgHandler.setText))
//    }
//    
//    func onCardInteractionComplete() {
//        subject.send(.cardInteractionComplete)
//    }
//    
//    func onCardRecognized() {
//        subject.send(.cardRecognized)
//    }
//    
//    func onCardRemoved() {
//        subject.send(.cardRemoved)
//    }
//}
