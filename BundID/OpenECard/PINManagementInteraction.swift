import Foundation
import Combine
import OpenEcard

class PINManagementInteraction: NSObject, PinManagementInteractionProtocol {
    
    private let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
    
    var publisher: EIDInteractionPublisher { subject.eraseToAnyPublisher() }
    
    func onPinChangeable(_ enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        onGeneralPINChangeable(attempts: nil, enterOldAndNewPIN: enterOldNewPins)
    }
    
    func onPinChangeable(_ attempts: Int32, withEnterOldNewPins enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        onGeneralPINChangeable(attempts: Int(attempts), enterOldAndNewPIN: enterOldNewPins)
    }
    
    private func onGeneralPINChangeable(attempts: Int?, enterOldAndNewPIN: ConfirmOldSetNewPasswordOperationProtocol) {
        subject.send(.requestChangedPIN(attempts: attempts, pinCallback: enterOldAndNewPIN.confirmPassword))
    }
    
    func onPinCanNewPinRequired(_ enterPinCanNewPin: (NSObjectProtocol & ConfirmPinCanNewPinOperationProtocol)!) {
        subject.send(.requestCANAndChangedPIN(pinCallback: enterPinCanNewPin.confirmChangePassword))
    }
    
    func onPinBlocked(_ unblockWithPuk: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        subject.send(.requestPUK(unblockWithPuk.confirmPassword))
    }
    
    func onCardPukBlocked() {
        subject.send(completion: .failure(.cardBlocked))
    }
    
    func onCardDeactivated() {
        subject.send(completion: .failure(.cardDeactivated))
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
