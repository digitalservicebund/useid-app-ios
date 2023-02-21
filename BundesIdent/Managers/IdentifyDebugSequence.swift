import Foundation
import Combine

#if PREVIEW

extension [IdentifyDebugSequence] {
    static var initial: [Element] {
        [.loadError, .requestAuthorization]
    }
    
    static var initialCAN: [Element] {
        [.cancel, .identifySuccessfully, .runCANError, .runPINError(remainingAttempts: 1)]
    }
}

enum IdentifyDebugSequence: Identifiable, Equatable {
    
    case cancel
    case requestAuthorization
    case runPINError(remainingAttempts: Int)
    case runNFCError
    case askForCAN
    case runCardDeactivated
    case runCardBlocked
    case loadError
    case identifySuccessfully
    case missingRedirect
    case runCANError
    
    var id: String {
        switch self {
        case .cancel: return "cancel"
        case .requestAuthorization: return "requestAuthorization"
        case .runPINError(let remainingAttempts): return "runPINError (\(remainingAttempts))"
        case .runNFCError: return "runNFCError"
        case .askForCAN: return "askForCAN"
        case .runCardDeactivated: return "runCardDeactivated"
        case .runCardBlocked: return "runCardBlocked"
        case .loadError: return "loadError"
        case .identifySuccessfully: return "identifySuccessfully"
        case .missingRedirect: return "missingRedirect"
        case .runCANError: return "runCANError"
        }
    }
    
    private func requestInput(card: Card, subject: PassthroughSubject<EIDInteractionEvent, IDCardInteractionError>) -> [IdentifyDebugSequence] {
        let callback = {
            subject.send(.requestCardInsertion({ _ in }))
        }
        
        if card.remainingAttempts >= 2 {
            subject.send(.requestPIN(remainingAttempts: card.remainingAttempts, pinCallback: { _ in callback() }))
            return [.cancel, .identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .runNFCError]
        } else if card.remainingAttempts == 1 {
            subject.send(.requestPINAndCAN({ _, _ in callback() }))
            return [.cancel, .identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .runNFCError, .runCANError]
        } else {
            subject.send(completion: .failure(.cardBlocked))
            return []
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
            return [.identifySuccessfully, .missingRedirect, .runPINError(remainingAttempts: card.remainingAttempts), .runCardBlocked, .askForCAN, .runCardDeactivated, .cancel]
        case .cancel:
            subject.send(.cardInteractionComplete)
            let callback = {
                subject.send(.requestCardInsertion({ _ in }))
            }
            
            if card.remainingAttempts >= 2 {
                subject.send(.requestPIN(remainingAttempts: nil, pinCallback: { _ in callback() }))
                return [.cancel, .identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .runNFCError]
            } else if card.remainingAttempts == 1 {
                subject.send(.requestPINAndCAN({ _, _ in callback() }))
                return [.cancel, .identifySuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .runNFCError, .runCANError]
            } else {
                subject.send(completion: .failure(.cardBlocked))
                return []
            }
        case .identifySuccessfully:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.authenticationSuccessful)
            subject.send(.processCompletedSuccessfullyWithRedirect(url: URL(string: "https://example.org")!))
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
        case .runPINError(remainingAttempts: let remainingAttempts):
            card.remainingAttempts = remainingAttempts - 1
            
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.cardRemoved)
            
            return requestInput(card: card, subject: subject)
        case .runNFCError:
            subject.send(completion: .failure(.processFailed(resultCode: .INTERNAL_ERROR, redirectURL: nil, resultMinor: nil)))
            return [.cancel]
        case .askForCAN:
            card.remainingAttempts = 1
            return requestInput(card: card, subject: subject)
        case .runCardDeactivated:
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(completion: .failure(.cardDeactivated))
            return []
        case .runCardBlocked:
            card.remainingAttempts = 0
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
            return [.cancel, .identifySuccessfully, .runCANError, .runPINError(remainingAttempts: card.remainingAttempts)]
        }
    }
}

#endif
