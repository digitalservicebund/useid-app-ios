//
//  ContentView.swift
//  BundID
//
//  Created by Fabio Tacke on 20.04.22.
//

import SwiftUI
import OpenEcard

struct ContentView: View {
    let nfcManager = NFCManager()
    
    var body: some View {
        Button("Go") {
            nfcManager.identify()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct NFCManager {
    let openEcard = OpenEcardImp()!
    
    func identify() {
        let context = openEcard.context(NFCCofig())!
        context.initializeContext(StartServiceHandler())
    }
}

class NFCCofig: NSObject, NFCConfigProtocol {
    func getProvideCardMessage() -> String! {
        "getProvideCardMessage()"
    }
    
    func getDefaultNFCCardRecognizedMessage() -> String! {
        "getDefaultNFCCardRecognizedMessage()"
    }
    
    func getDefaultNFCErrorMessage() -> String! {
        "getDefaultNFCErrorMessage()"
    }
    
    func getAquireNFCTagTimeoutMessage() -> String! {
        "getAquireNFCTagTimeoutMessage()"
    }
    
    func getNFCCompletionMessage() -> String! {
        "getNFCCompletionMessage()"
    }
    
    func getTagLostErrorMessage() -> String! {
        "getTagLostErrorMessage()"
    }
    
    func getDefaultCardConnectedMessage() -> String! {
        "getDefaultCardConnectedMessage()"
    }
}

class StartServiceHandler: NSObject, StartServiceHandlerProtocol {
    func onSuccess(_ source: (NSObjectProtocol & ActivationSourceProtocol)!) {
        print("onSuccess")
        
        let urlString = "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%2FAutent-DemoApplication%2FRequestServlet%3Fprovider%3Ddemo_epa_20%26redirect%3Dtrue"
        let eacController = source.eacFactory().create(urlString, withActivation: ControllerCallback(), with: EACInteraction())
//        let pinChangeController = source.pinManagementFactory().create(ControllerCallback(), with: PinManagementInteraction())
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        print("onFailure")
    }
}

class ControllerCallback: NSObject, ControllerCallbackProtocol {
    func onStarted() {
        print("onStarted")
    }
    
    func onAuthenticationCompletion(_ result: (NSObjectProtocol & ActivationResultProtocol)!) {
        print("onAuthenticationCompletion")
    }
}

class EACInteraction: NSObject, EacInteractionProtocol {
    func onCanRequest(_ enterCan: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("onCanRequest")
    }
    
    func onPinRequest(_ enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("onPinRequest")
        enterPin.confirmPassword("123456")
    }
    
    func onPinRequest(_ attempt: Int32, withEnterPin enterPin: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("onPinRequest with attempts: \(attempt)")
    }
    
    func onPinCanRequest(_ enterPinCan: (NSObjectProtocol & ConfirmPinCanOperationProtocol)!) {
        print("onPinCanRequest")
    }
    
    func onCardBlocked() {
        print("onCardBlocked")
    }
    
    func onCardDeactivated() {
        print("onCardDeactivated")
    }
    
    func onServerData(_ data: (NSObjectProtocol & ServerDataProtocol)!, withTransactionData transactionData: String!, withSelectReadWrite selectReadWrite: (NSObjectProtocol & ConfirmAttributeSelectionOperationProtocol)!) {
        print("onServerData")
        selectReadWrite.enterAttributeSelection([], withWrite: [])
    }
    
    func onCardAuthenticationSuccessful() {
        print("onCardAuthenticationSuccessful")
    }
    
    func requestCardInsertion() {
        print("requestCardInsertion")
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        print("requestCardInsertion with msgHandler")
    }
    
    func onCardInteractionComplete() {
        print("onCardInteractionComplete")
    }
    
    func onCardRecognized() {
        print("onCardRecognized")
    }
    
    func onCardRemoved() {
        print("onCardRemoved")
    }
}

class PinManagementInteraction: NSObject, PinManagementInteractionProtocol {
    func onPinChangeable(_ enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        print("onPinChangeable")
        enterOldNewPins.confirmPassword("123456", withNewPassword: "000000")
    }
    
    func onPinChangeable(_ attempts: Int32, withEnterOldNewPins enterOldNewPins: (NSObjectProtocol & ConfirmOldSetNewPasswordOperationProtocol)!) {
        print("onPinChangeable attempts: \(attempts)")
        enterOldNewPins.confirmPassword("123456", withNewPassword: "000000")
    }
    
    func onPinCanNewPinRequired(_ enterPinCanNewPin: (NSObjectProtocol & ConfirmPinCanNewPinOperationProtocol)!) {
        print("onPinCanNewPinRequired")
    }
    
    func onPinBlocked(_ unblockWithPuk: (NSObjectProtocol & ConfirmPasswordOperationProtocol)!) {
        print("onPinBlocked")
    }
    
    func onCardPukBlocked() {
        print("onCardPukBlocked")
    }
    
    func onCardDeactivated() {
        print("onCardDeactivated")
    }
    
    func requestCardInsertion() {
        print("requestCardInsertion")
    }
    
    func requestCardInsertion(_ msgHandler: (NSObjectProtocol & NFCOverlayMessageHandlerProtocol)!) {
        print("requestCardInsertion with mshHandler")
    }
    
    func onCardInteractionComplete() {
        print("onCardInteractionComplete")
    }
    
    func onCardRecognized() {
        print("onCardRecognized")
    }
    
    func onCardRemoved() {
        print("onCardRemoved")
    }
}
