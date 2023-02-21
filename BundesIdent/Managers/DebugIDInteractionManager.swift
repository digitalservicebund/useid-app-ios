import Foundation
import OpenEcard
import Combine

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

class DebugIDInteractionManager: IDInteractionManagerType {
    private var subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>?
    private var card: Card = .init(remainingAttempts: 3)
    
    func debuggableIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        DebuggableInteraction(publisher: identify(tokenURL: tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider(nfcMessages: .identification)),
                              sequence: .initial)
    }
    
    func debuggableCANIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        DebuggableInteraction(publisher: identify(tokenURL: tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider(nfcMessages: .identification)),
                              sequence: .initialCAN)
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
        transactionInfo: nil,
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
