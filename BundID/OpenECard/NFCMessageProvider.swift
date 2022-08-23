import Foundation
import OpenEcard

struct NFCMessages: Equatable {
    var provideCardMessage = L10n.CardInteraction.provideCard
    var defaultNFCCardRecognizedMessage = L10n.CardInteraction.cardRecognized
    var defaultNFCErrorMessage = L10n.CardInteraction.Error.default
    var aquireNFCTagTimeoutMessage = L10n.CardInteraction.Error.timeout
    var nfcCompletionMessage: String
    var tagLostErrorMessage = L10n.CardInteraction.Error.tagLost
    var defaultCardConnectedMessage = L10n.CardInteraction.cardConnected
    
    static let setup = NFCMessages(nfcCompletionMessage: L10n.FirstTimeUser.Scan.scanSuccess)
    static let identification = NFCMessages(nfcCompletionMessage: L10n.Identification.Scan.scanSuccess)
}

class NFCMessageProvider: NSObject, NFCConfigProtocol {
    
    var nfcMessages: NFCMessages
    
    init(nfcMessages: NFCMessages) {
        self.nfcMessages = nfcMessages
    }
    
    func getProvideCardMessage() -> String! {
        nfcMessages.provideCardMessage
    }
    
    func getDefaultNFCCardRecognizedMessage() -> String! {
        nfcMessages.defaultNFCCardRecognizedMessage
    }
    
    func getDefaultNFCErrorMessage() -> String! {
        nfcMessages.defaultNFCErrorMessage
    }
    
    func getAquireNFCTagTimeoutMessage() -> String! {
        nfcMessages.aquireNFCTagTimeoutMessage
    }
    
    func getNFCCompletionMessage() -> String! {
        nfcMessages.nfcCompletionMessage
    }
    
    func getTagLostErrorMessage() -> String! {
        nfcMessages.tagLostErrorMessage
    }
    
    func getDefaultCardConnectedMessage() -> String! {
        nfcMessages.defaultCardConnectedMessage
    }
}
