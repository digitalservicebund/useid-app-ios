// This file is used for mock generation via Cuckoo

import Foundation
import OpenEcard
import Combine

protocol IDInteractionManagerType {
    func identify(tokenURL: String) -> EIDInteractionPublisher
    func changePIN() -> EIDInteractionPublisher
}

protocol OpenEcardType: OpenEcardProtocol {
    func context(_ nfcConfig: (NSObjectProtocol & NFCConfigProtocol)!) -> (NSObjectProtocol & ContextManagerProtocol)!
    func context(_ defaultNFCDialgoMsg: String!, withDefaultNFCCardRecognizedMessage: String!) -> (NSObjectProtocol & ContextManagerProtocol)!
    func prepareTCTokenURL(_ tcTokenURL: String!) -> String!
    func setDebugLogLevel()
    func developerOptions() -> (NSObjectProtocol & DeveloperOptionsProtocol)!
}

protocol ContextManagerType: ContextManagerProtocol {
    func initializeContext(_ handler: (NSObjectProtocol & StartServiceHandlerProtocol))
    func terminateContext(_ handler: (NSObjectProtocol & StopServiceHandlerProtocol)!)
}
