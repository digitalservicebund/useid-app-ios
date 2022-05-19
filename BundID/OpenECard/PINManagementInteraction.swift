import Foundation
import Combine
import OpenEcard

class PINManagementInteraction<S>: OpenECardHandlerBase<S>, PinManagementInteractionProtocol where S: Subscriber, IDCardInteractionError == S.Failure, EIDInteractionEvent == S.Input {
    func onPinChangeable(_ enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        onGeneralPINChangeable(attempts: nil, enterOldAndNewPIN: enterOldNewPins)
    }
    
    func onPinChangeable(_ attempts: Int32, withEnterOldNewPins enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        onGeneralPINChangeable(attempts: Int(attempts), enterOldAndNewPIN: enterOldNewPins)
    }
    
    private func onGeneralPINChangeable(attempts: Int?, enterOldAndNewPIN: ConfirmOldSetNewPasswordOperationProtocol) {
        delegate.send(event: .requestChangedPIN(attempts: attempts, pinCallback: enterOldAndNewPIN.confirmPassword))
    }
    
    func onPinCanNewPinRequired(_ enterPinCanNewPin: (NSObjectProtocol & ConfirmPinCanNewPinOperationProtocol)!) {
        delegate.send(event: .requestCANAndChangedPIN(pinCallback: enterPinCanNewPin.confirmChangePassword))
    }
    
    func onPinBlocked(_ unblockWithPuk: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        delegate.send(event: .requestPUK(unblockWithPuk.confirmPassword))
    }
    
    func onCardPukBlocked() {
        delegate.fail(error: .cardBlocked)
    }
    
    func onCardDeactivated() {
        delegate.fail(error: .cardDeactivated)
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
