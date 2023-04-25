import Foundation
import Combine

#if PREVIEW

extension [IdentifyDebugSequence] {
    static var initial: [Element] {
        [.loadError, .requestAuthorization]
    }
    
    static var initialCAN: [Element] {
        [.identifySuccessfully, .runCANError, .runPINError(initial: true, remainingAttempts: 3)]
    }
}

enum IdentifyDebugSequence: Identifiable, Equatable {
    
    case requestAuthorization
    case runPINError(initial: Bool, remainingAttempts: Int)
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
        case .requestAuthorization: return "requestAuthorization"
        case .runPINError(initial: _, let remainingAttempts): return "runPINError (\(remainingAttempts))"
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
    
    func run(card: inout Card, subject: PassthroughSubject<EIDInteractionEvent, EIDInteractionError>) -> [IdentifyDebugSequence] {
        switch self {
        case .loadError:
            subject.send(completion: .failure(.authenticationFailed(resultMajor: "error", resultMinor: "debugError", refreshURL: nil)))
            return []
        case .requestAuthorization:
            subject.send(.authenticationRequestConfirmationRequested(.init(requiredAttributes: [.givenNames, .familyName, .dateOfBirth])))
            subject.send(.certificateDescriptionRetrieved(CertificateDescription.preview))
            return [.identifySuccessfully, .missingRedirect, .runPINError(initial: true, remainingAttempts: card.remainingAttempts), .runCardBlocked, .runCardSuspended, .runCardDeactivated]
        case .identifySuccessfully:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.authenticationSucceeded(redirectURL: URL(string: "https://example.org")!))
            subject.send(completion: .finished)
            return []
        case .missingRedirect:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.authenticationSucceeded(redirectURL: nil))
            subject.send(completion: .finished)
            return []
        case .runPINError(initial: let initial, remainingAttempts: let remainingAttempts):
            card.remainingAttempts = remainingAttempts - 1
            
            subject.send(.cardRecognized)
            
            if initial {
                subject.send(.pinRequested(remainingAttempts: remainingAttempts))
            }
            
            if card.remainingAttempts >= 2 {
                subject.send(.pinRequested(remainingAttempts: card.remainingAttempts))
                subject.send(.cardInsertionRequested)
            } else if card.remainingAttempts == 1 {
                subject.send(.canRequested)
                subject.send(.cardInsertionRequested)
            } else {
                subject.send(.pukRequested)
            }
            
            return [.identifySuccessfully, .runPINError(initial: false, remainingAttempts: card.remainingAttempts), .runCANError]
        case .runNFCError:
            subject.send(completion: .failure(.authenticationFailed(resultMajor: "error", resultMinor: "debugError", refreshURL: nil)))
            return []
        case .runCardSuspended:
            card.remainingAttempts = 1
            subject.send(.pinRequested(remainingAttempts: nil))
            subject.send(.canRequested)
            subject.send(.cardRemoved)
            subject.send(.cardInsertionRequested)
            return [.identifySuccessfully, .runCANError, .runPINError(initial: false, remainingAttempts: card.remainingAttempts)]
        case .runCardDeactivated:
            subject.send(.cardRecognized)
            subject.send(completion: .failure(.cardDeactivated))
            return []
        case .runCardBlocked:
            subject.send(.cardRecognized)
            subject.send(.pukRequested)
            return []
        case .runCANError:
            subject.send(.cardRecognized)
            subject.send(.pinRequested(remainingAttempts: nil))
            subject.send(.canRequested)
            subject.send(.cardInsertionRequested)
            subject.send(.cardRemoved)
            return [.identifySuccessfully, .runCANError, .runPINError(initial: false, remainingAttempts: card.remainingAttempts)]
        }
    }
}

#endif
