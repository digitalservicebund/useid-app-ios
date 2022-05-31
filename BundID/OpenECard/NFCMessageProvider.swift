import Foundation
import OpenEcard

class NFCMessageProvider: NSObject, NFCConfigProtocol {
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
