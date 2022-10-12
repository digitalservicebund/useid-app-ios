import Foundation
import OpenEcard

struct NFCMessages: Equatable {
    var provideCardMessage: String
    var defaultNFCCardRecognizedMessage: String
    var defaultCardConnectedMessage: String
    var nfcCompletionMessage: String
    
    var defaultNFCErrorMessage = L10n.CardInteraction.Error.default
    var aquireNFCTagTimeoutMessage = L10n.CardInteraction.Error.timeout
    var tagLostErrorMessage = L10n.CardInteraction.Error.tagLost
    
    static let identification = NFCMessages(provideCardMessage: L10n.Identification.Scan.provideCard,
                                            defaultNFCCardRecognizedMessage: L10n.Identification.Scan.cardRecognized,
                                            defaultCardConnectedMessage: L10n.Identification.Scan.cardConnected,
                                            nfcCompletionMessage: L10n.Identification.Scan.scanSuccess)
}

class SetupNFCMessageProvider: NSObject, NFCConfigProtocol {
    
    let setupFirst = NFCMessages(provideCardMessage: L10n.FirstTimeUser.Scan.ProvideCard.first,
                                 defaultNFCCardRecognizedMessage: L10n.FirstTimeUser.Scan.CardRecognized.first,
                                 defaultCardConnectedMessage: L10n.FirstTimeUser.Scan.CardConnected.first,
                                 nfcCompletionMessage: L10n.FirstTimeUser.Scan.ScanSuccess.first)
    
    let setupSecond = NFCMessages(provideCardMessage: L10n.FirstTimeUser.Scan.ProvideCard.second,
                                  defaultNFCCardRecognizedMessage: L10n.FirstTimeUser.Scan.CardRecognized.second,
                                  defaultCardConnectedMessage: L10n.FirstTimeUser.Scan.CardConnected.second,
                                  nfcCompletionMessage: L10n.FirstTimeUser.Scan.ScanSuccess.second)
    
    var isFirstScan = true
    var nfcMessages: NFCMessages {
        switch isFirstScan {
        case true: return setupFirst
        case false: return setupSecond
        }
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
        let message = nfcMessages.nfcCompletionMessage
        isFirstScan = false
        return message
    }
    
    func getTagLostErrorMessage() -> String! {
        nfcMessages.tagLostErrorMessage
    }
    
    func getDefaultCardConnectedMessage() -> String! {
        nfcMessages.defaultCardConnectedMessage
    }
}

class IdentificationNFCMessageProvider: NSObject, NFCConfigProtocol {
    
    var nfcMessages: NFCMessages
    
    init(nfcMessages: NFCMessages = .identification) {
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
