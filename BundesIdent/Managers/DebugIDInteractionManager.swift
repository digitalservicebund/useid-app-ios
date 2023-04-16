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

enum CancelAction: Equatable {
    case pin
    case can
}

class DebugIDInteractionManager: IDInteractionManagerType {
    private var subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>?
    private var card: Card = .init(remainingAttempts: 3)
    
    func debuggableIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        DebuggableInteraction(publisher: identify(tokenURL: tokenURL, messages: .identification),
                              sequence: .initial)
    }
    
    func debuggableCANIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        DebuggableInteraction(publisher: identify(tokenURL: tokenURL, messages: .identification),
                              sequence: .initialCAN)
    }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        
        subject.send(.authenticationStarted)
        subject.send(.cardInsertionRequested)
        
        return subject
            .eraseToAnyPublisher()
    }
    
    func debuggableChangePIN() -> DebuggableInteraction<ChangePINDebugSequence> {
        DebuggableInteraction(publisher: changePIN(messages: .setup),
                              sequence: ChangePINDebugSequence.defaultActions(card: card))
    }
    
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        
        subject.send(.authenticationStarted)
        subject.send(.cardInsertionRequested)
        
        return subject
            .eraseToAnyPublisher()
    }
    
    func runChangePIN(debugSequence: ChangePINDebugSequence) -> [ChangePINDebugSequence] {
        debugSequence.run(card: &card, subject: subject!)
    }
    
    func runIdentify(debugSequence: IdentifyDebugSequence) -> [IdentifyDebugSequence] {
        debugSequence.run(card: &card, subject: subject!)
    }

    func setPIN(_ pin: String) {
        // TODO: What do we need to do here?
    }

    func setNewPIN(_ pin: String) {
        // TODO: What do we need to do here?
    }

    func setCAN(_ can: String) {
        // TODO: What do we need to do here?
    }

    func retrieveCertificateDescription() {
        // TODO: What do we need to do here?
    }

    func acceptAccessRights() {
        // TODO: What do we need to do here?
    }
    
    func interrupt() {}
    
    func cancel() {
        // TODO: What do we need to do here?
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

extension AuthenticationInformation {
    static var preview: AuthenticationInformation = .init(request: .preview, certificateDescription: .preview)
}

extension AuthenticationRequest {
    static var preview: AuthenticationRequest = .init(requiredAttributes: [.DG01, .DG02, .DG03, .DG04])
}

extension CertificateDescription {
    static let preview = CertificateDescription(
        issuerName: "Issuer",
        issuerUrl: URL(string: "https://issuer.com")!,
        purpose: "Purpose",
        subjectName: "Subject",
        subjectUrl: URL(string: "https://subject.com")!,
        termsOfUsage: AuthenticationTerms.text("Terms").description,
        effectiveDate: Date(),
        expirationDate: Date().addingTimeInterval(24 * 60 * 60)
    )
}

#endif
