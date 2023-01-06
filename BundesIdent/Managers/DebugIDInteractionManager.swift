import Combine
import Foundation
import OpenEcard

#if PREVIEW

func processInfoContainsArgument(_ argument: String) -> Bool {
    ProcessInfo.processInfo.arguments.contains(argument)
}

struct DebuggableInteraction<T> {
    var publisher: EIDInteractionPublisher
    var sequence: [T]
}

struct Card {
    var remainingAttempts: Int = 3
}

enum CancelAction {
    case pin
    case can
}

enum IdentifyDebugSequence: Identifiable, Equatable {
    case cancelPINScan
    case cancelCANScan
    case requestAuthorization
    case runPINError(remainingAttempts: Int, cancelAction: CancelAction)
    case runNFCError
    case runCardSuspended
    case runCardDeactivated
    case runCardBlocked
    case loadError
    case identifySuccessfully
    case missingRedirect
    case runCANError
    
    var id: String {
        switch self {
        case .cancelPINScan: return "cancelPINScan"
        case .cancelCANScan: return "cancelCANScan"
        case .requestAuthorization: return "requestAuthorization"
        case .runPINError(let remainingAttempts, _): return "runPINError (\(remainingAttempts))"
        case .runNFCError: return "runNFCError"
        case .runCardSuspended: return "runCardSuspended"
        case .runCardDeactivated: return "runCardDeactivated"
        case .runCardBlocked: return "runCardBlocked"
        case .loadError: return "loadError"
        case .identifySuccessfully: return "identifySuccessfully"
        case .missingRedirect: return "missingRedirect"
        case .runCANError: return "runCANError"
        }
    }
    
    func run(card: inout Card, subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>) -> [IdentifyDebugSequence] {
        switch self {
        case .loadError:
            subject.send(completion: .failure(.processFailed(resultCode: .DEPENDING_HOST_UNREACHABLE, redirectURL: nil, resultMinor: nil)))
            return []
        case .requestAuthorization:
            subject.send(.requestAuthenticationRequestConfirmation(EIDAuthenticationRequest.preview, { _ in
                subject.send(.requestPIN(remainingAttempts: nil, pinCallback: { _ in
                    subject.send(.authenticationStarted)
                    subject.send(.requestCardInsertion({ _ in }))
                }))
            }))
            return [.identifySuccessfully, .missingRedirect, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .pin), .runCardBlocked, .runCardSuspended, .runCardDeactivated, .cancelPINScan]
        case .cancelPINScan:
            subject.send(.cardInteractionComplete)
            subject.send(.requestPIN(remainingAttempts: nil, pinCallback: { _ in
                subject.send(.requestCardInsertion({ _ in }))
            }))
            return [.identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .pin), .runCardBlocked, .runCardSuspended, .runCardDeactivated, .cancelPINScan]
        case .cancelCANScan:
            subject.send(.cardInteractionComplete)
            subject.send(.requestPINAndCAN({ _, _ in
                subject.send(.requestCardInsertion({ _ in }))
            }))
            return [.identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .can), .runCardDeactivated, .runCANError, .cancelCANScan]
        case .identifySuccessfully:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.authenticationSuccessful)
            subject.send(.processCompletedSuccessfullyWithRedirect(url: URL(string: "https://verylonglink.com/aspdkljaskjhfkjsahfsjkdfhjksdhfsdkjfhasd")!))
            subject.send(completion: .finished)
            return []
        case .missingRedirect:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.authenticationSuccessful)
            subject.send(.processCompletedSuccessfullyWithoutRedirect)
            subject.send(completion: .finished)
            return []
        case .runPINError(remainingAttempts: let remainingAttempts, cancelAction: let cancelAction):
            let callback = {
                subject.send(.requestCardInsertion({ _ in }))
            }
            
            card.remainingAttempts = remainingAttempts - 1
            
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.cardRemoved)
            
            if card.remainingAttempts >= 2 {
                subject.send(.requestPIN(remainingAttempts: card.remainingAttempts, pinCallback: { _ in callback() }))
            } else if card.remainingAttempts == 1 {
                subject.send(.requestPINAndCAN({ _, _ in callback() }))
            } else {
                subject.send(completion: .failure(.cardBlocked))
            }
            
            let cancelDebugSequence: IdentifyDebugSequence
            switch cancelAction {
            case .pin: cancelDebugSequence = .cancelPINScan
            case .can: cancelDebugSequence = .cancelCANScan
            }
            
            return [.identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: cancelAction), .runCANError, cancelDebugSequence]
        case .runNFCError:
            subject.send(completion: .failure(.processFailed(resultCode: .INTERNAL_ERROR, redirectURL: nil, resultMinor: nil)))
            return [.cancelCANScan, .cancelPINScan]
        case .runCardSuspended:
            let callback = {
                subject.send(.cardRemoved)
                subject.send(.requestCardInsertion({ _ in }))
            }
            card.remainingAttempts = 1
            subject.send(.requestPINAndCAN({ _, _ in callback() }))
            return [.cancelCANScan, .identifySuccessfully, .runCANError, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .can)]
        case .runCardDeactivated:
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(completion: .failure(.cardDeactivated))
            return []
        case .runCardBlocked:
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(completion: .failure(.cardBlocked))
            return []
        case .runCANError:
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.requestPINAndCAN { _, _ in
                subject.send(.requestCardInsertion { _ in })
            })
            subject.send(.cardRemoved)
            return [.cancelCANScan, .identifySuccessfully, .runCANError, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .can)]
        }
    }
}

enum ChangePINDebugSequence: Identifiable, Equatable {
    case cancel
    case changePINSuccessfully
    case runPINError(remainingAttempts: Int)
    case runNFCError
    case runCardSuspended
    case runCardDeactivated
    case runCardBlocked
    
    var id: String {
        switch self {
        case .cancel: return "cancel"
        case .changePINSuccessfully: return "changePINSuccessfully"
        case .runPINError: return "runPINError"
        case .runNFCError: return "runNFCError"
        case .runCardSuspended: return "runCardSuspended"
        case .runCardDeactivated: return "runCardDeactivated"
        case .runCardBlocked: return "runCardBlocked"
        }
    }
    
    static func defaultActions(card: Card) -> [ChangePINDebugSequence] {
        var actions: [ChangePINDebugSequence] = [
            .cancel,
            .changePINSuccessfully,
            .runCardSuspended,
            .runNFCError,
            .runCardDeactivated,
            .runCardBlocked
        ]
        
        if card.remainingAttempts >= 0 {
            actions.append(.runPINError(remainingAttempts: card.remainingAttempts))
        }
        
        return actions
    }
    
    func run(card: inout Card, subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>) -> [ChangePINDebugSequence] {
        switch self {
        case .cancel:
            subject.send(.requestChangedPIN(remainingAttempts: nil, pinCallback: { _, _ in }))
            return []
        case .changePINSuccessfully:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.processCompletedSuccessfullyWithoutRedirect)
            subject.send(completion: .finished)
            return []
        case .runPINError(remainingAttempts: let remainingAttempts):
            
            let secondCallback = {
                subject.send(.cardRemoved)
                subject.send(.requestCardInsertion({ _ in }))
            }
            
            card.remainingAttempts = remainingAttempts - 1
            
            let firstCallback = { [card] in
                subject.send(.cardRemoved)
                subject.send(.requestCardInsertion({ _ in }))
                subject.send(.cardRecognized)
                subject.send(.cardInteractionComplete)
                
                if card.remainingAttempts >= 2 {
                    subject.send(.requestChangedPIN(remainingAttempts: card.remainingAttempts, pinCallback: { _, _ in secondCallback() }))
                } else if card.remainingAttempts == 1 {
                    subject.send(.requestCANAndChangedPIN(pinCallback: { _, _, _ in secondCallback() }))
                } else {
                    subject.send(completion: .failure(.cardBlocked))
                }
            }
            
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.requestChangedPIN(remainingAttempts: remainingAttempts, pinCallback: { _, _ in firstCallback() }))
            
            return ChangePINDebugSequence.defaultActions(card: card)
        case .runNFCError:
            subject.send(completion: .failure(.processFailed(resultCode: .INTERNAL_ERROR, redirectURL: nil, resultMinor: nil)))
            return ChangePINDebugSequence.defaultActions(card: card)
        case .runCardSuspended:
            subject.send(.requestCANAndChangedPIN(pinCallback: { _, _, _ in }))
            return ChangePINDebugSequence.defaultActions(card: card)
        case .runCardDeactivated:
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(completion: .failure(.cardDeactivated))
            return []
        case .runCardBlocked:
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(completion: .failure(.cardBlocked))
            return []
        }
    }
}

class DebugIDInteractionManager: IDInteractionManagerType {
    private var subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>?
    private var card: Card = .init(remainingAttempts: 3)
    
    func debuggableIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        DebuggableInteraction(publisher: identify(tokenURL: tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider(nfcMessages: .identification)),
                              sequence: [.loadError, .requestAuthorization])
    }
    
    func debuggableCANIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        DebuggableInteraction(publisher: identify(tokenURL: tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider(nfcMessages: .identification)),
                              sequence: [.cancelCANScan, .identifySuccessfully, .runCANError, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .can)])
    }
    
    func identify(tokenURL: URL, nfcMessagesProvider: NSObjectProtocol & NFCConfigProtocol) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        
        return subject
            .eraseToAnyPublisher()
    }
    
    func debuggableChangePIN() -> DebuggableInteraction<ChangePINDebugSequence> {
        DebuggableInteraction(publisher: changePIN(nfcMessagesProvider: SetupNFCMessageProvider()),
                              sequence: ChangePINDebugSequence.defaultActions(card: card))
    }
    
    func changePIN(nfcMessagesProvider: NSObjectProtocol & NFCConfigProtocol) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        
        return subject
            .eraseToAnyPublisher()
    }
    
    func runChangePIN(debugSequence: ChangePINDebugSequence) -> [ChangePINDebugSequence] {
        debugSequence.run(card: &card, subject: subject!)
    }
    
    func runIdentify(debugSequence: IdentifyDebugSequence) -> [IdentifyDebugSequence] {
        debugSequence.run(card: &card, subject: subject!)
    }
}
#endif

#if DEBUG || PREVIEW

extension EIDAuthenticationRequest {
    static let preview = EIDAuthenticationRequest(
        issuer: "Issuer",
        issuerURL: "https://issuer.com",
        subject: "Subject",
        subjectURL: "https://subject.com",
        validity: "Validity",
        terms: AuthenticationTerms.text("Terms"),
        transactionInfo: "{\"providerName\":\"Sparkasse\",\"providerURL\":\"https://sparkasse.de\",\"additionalInfo\":[{\"key\":\"Kundennummer\",\"value\":\"23467812\"},{\"key\":\"Nachname\",\"value\":\"Mustermann\"}]}",
        readAttributes: [
            .DG01: true,
            .DG02: true,
            .DG03: true,
            .DG04: true,
            .DG05: false,
            .DG06: false
        ]
    )
}

#endif
