import Foundation
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

class DebugEIDInteractionManager: EIDInteractionManagerType {
    private var subject: PassthroughSubject<EIDInteractionEvent, EIDInteractionError>?
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
        let subject = PassthroughSubject<EIDInteractionEvent, EIDInteractionError>()
        self.subject = subject
        
        subject.send(.identificationStarted)
        subject.send(.cardInsertionRequested)
        
        return subject
            .eraseToAnyPublisher()
    }
    
    func debuggableChangePIN() -> DebuggableInteraction<ChangePINDebugSequence> {
        DebuggableInteraction(publisher: changePIN(messages: .setup),
                              sequence: ChangePINDebugSequence.defaultActions(card: card))
    }
    
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, EIDInteractionError>()
        self.subject = subject
        
        subject.send(.identificationStarted)
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
}
#endif

#if DEBUG || PREVIEW

extension IdentificationInformation {
    static var preview: Self = .init(request: .preview, certificateDescription: .preview)
}

extension IdentificationRequest {
    static var preview: Self = .init(requiredAttributes: [.documentType,
                                                          .issuingCountry,
                                                          .validUntil,
                                                          .artisticName])
}

extension CertificateDescription {
    static let preview = CertificateDescription(
        issuerName: "Issuer name placeholder",
        issuerURL: URL(string: "https://issuer.com")!,
        purpose: "Purpose placeholder",
        subjectName: "Subject placeholder",
        subjectURL: URL(string: "https://subject.com")!,
        termsOfUsage: "Terms of usage placeholder",
        effectiveDate: Date(),
        expirationDate: Date().addingTimeInterval(24 * 60 * 60)
    )
}

#endif
