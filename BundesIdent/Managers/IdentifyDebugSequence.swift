import Foundation
import Combine

#if PREVIEW

extension [IdentifyDebugSequence] {
    static var initial: [Element] {
        [.loadError, .requestAuthorization]
    }
    
    static var initialCAN: [Element] {
        [.cancelCANScan, .identifySuccessfully, .runCANError, .runPINError(remainingAttempts: 3, cancelAction: .can)]
    }
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

#endif
