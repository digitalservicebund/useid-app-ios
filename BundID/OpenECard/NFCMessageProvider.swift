//
//  NFCMessageProvider.swift
//  BundID
//
//  Created by Fabio Tacke on 21.04.22.
//

import Foundation
import OpenEcard

class NFSMessageProvider: NSObject, NFCConfigProtocol {
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
