import Foundation
import OpenEcard
import Combine

#if PREVIEW

func processInfoContainsArgument(_ argument: String) -> Bool {
    ProcessInfo.processInfo.arguments.contains(argument)
}

#if targetEnvironment(simulator)
let MOCK_OPENECARD = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil // Always mock except in unit tests
#else
let MOCK_OPENECARD = !processInfoContainsArgument("REAL_OPENECARD")
#endif

struct DebuggableInteraction<T> {
    var publisher: EIDInteractionPublisher
    var sequence: [T]
}

struct Card {
    var remainingAttempts: Int = 3
}

enum IdentifyDebugSequence: Identifiable, Equatable {
    case cancel
    case requestAuthorization
    case runPINError(remainingAttempts: Int)
    case runNFCError
    case runCardSuspended
    case runCardDeactivated
    case runCardBlocked
    case loadError
    case identifySuccessfully
    
    var id: String {
        switch self {
        case .cancel: return "cancel"
        case .requestAuthorization: return "requestAuthorization"
        case .runPINError(let remainingAttempts): return "runPINError (\(remainingAttempts))"
        case .runNFCError: return "runNFCError"
        case .runCardSuspended: return "runCardSuspended"
        case .runCardDeactivated: return "runCardDeactivated"
        case .runCardBlocked: return "runCardBlocked"
        case .loadError: return "loadError"
        case .identifySuccessfully: return "identifySuccessfully"
        }
    }
    
    static func defaultScanningActions(card: Card) -> [IdentifyDebugSequence] {
        let actions: [IdentifyDebugSequence] = [
            .cancel
        ]
        
        return actions
    }
    
    func run(card: inout Card, subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>) -> [IdentifyDebugSequence] {
        switch self {
        case .loadError:
            subject.send(completion: .failure(.processFailed(resultCode: .DEPENDING_HOST_UNREACHABLE)))
            return []
        case .requestAuthorization:
            subject.send(.requestAuthenticationRequestConfirmation(EIDAuthenticationRequest.preview, { _ in
                subject.send(.requestPIN(remainingAttempts: nil, pinCallback: { _ in
                    subject.send(.authenticationStarted)
                    subject.send(.requestCardInsertion({ _ in }))
                }))
            }))
            return [.identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .runCardBlocked, .runCardSuspended, .runCardDeactivated, .cancel]
        case .cancel:
            subject.send(.requestPIN(remainingAttempts: nil, pinCallback: { _ in }))
            return [.identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .runCardBlocked, .runCardSuspended, .runCardDeactivated, .cancel]
        case .identifySuccessfully:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.authenticationSuccessful)
            subject.send(.processCompletedSuccessfully)
            subject.send(completion: .finished)
            return []
        case .runPINError(remainingAttempts: let remainingAttempts):
            let callback = {
                subject.send(.cardRemoved)
                subject.send(.requestCardInsertion({ _ in }))
            }
            
            card.remainingAttempts = remainingAttempts - 1
            
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            
            if card.remainingAttempts >= 2 {
                subject.send(.requestPIN(remainingAttempts: card.remainingAttempts, pinCallback: { _ in callback() }))
            } else if card.remainingAttempts == 1 {
                subject.send(.requestPINAndCAN({ _, _ in }))
            } else {
                subject.send(completion: .failure(.cardBlocked))
            }
            
            return [.identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .cancel]
        case .runNFCError:
            subject.send(completion: .failure(.processFailed(resultCode: .INTERNAL_ERROR)))
            return IdentifyDebugSequence.defaultScanningActions(card: card)
        case .runCardSuspended:
            subject.send(.requestPINAndCAN({ _, _ in }))
            return IdentifyDebugSequence.defaultScanningActions(card: card)
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
            subject.send(.processCompletedSuccessfully)
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
            subject.send(completion: .failure(.processFailed(resultCode: .INTERNAL_ERROR)))
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
    
    func debuggableIdentify(tokenURL: String) -> DebuggableInteraction<IdentifyDebugSequence> {
        return DebuggableInteraction(publisher: identify(tokenURL: tokenURL),
                                     sequence: [.loadError, .requestAuthorization])
    }
    
    func identify(tokenURL: String) -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        
        return subject
            .eraseToAnyPublisher()
    }
    
    func debuggableChangePIN() -> DebuggableInteraction<ChangePINDebugSequence> {
        return DebuggableInteraction(publisher: changePIN(),
                                     sequence: ChangePINDebugSequence.defaultActions(card: card))
    }
    
    func changePIN() -> EIDInteractionPublisher {
        let subject = PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>()
        self.subject = subject
        
        subject.send(.authenticationStarted)
        subject.send(.requestCardInsertion({ _ in }))
        
        return subject
            .eraseToAnyPublisher()
    }
    
    var card: Card = Card(remainingAttempts: 3)
    
    func runChangePIN(debugSequence: ChangePINDebugSequence) -> [ChangePINDebugSequence] {
        return debugSequence.run(card: &card, subject: subject!)
    }
    
    func runIdentify(debugSequence: IdentifyDebugSequence) -> [IdentifyDebugSequence] {
        return debugSequence.run(card: &card, subject: subject!)
    }
}
#endif

extension EIDAuthenticationRequest {
    static let preview = EIDAuthenticationRequest(
        issuer: "Issuer",
        issuerURL: "https://issuer.com",
        subject: "Subject",
        subjectURL: "https://subject.com",
        validity: "Validity",
        terms: AuthenticationTerms.text("Terms"),
        readAttributes: [.DG01: true,
        .DG02: true,
        .DG03: true,
        .DG04: true,
        .DG05: false,
        .DG06: false]
    )
}
