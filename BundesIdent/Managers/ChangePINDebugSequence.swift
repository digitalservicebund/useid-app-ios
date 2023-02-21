import Foundation
import Combine

#if PREVIEW

enum ChangePINDebugSequence: Identifiable, Equatable {
    case cancel
    case changePINSuccessfully
    case runPINError(remainingAttempts: Int)
    case runNFCError
    case askForCAN
    case runCardDeactivated
    case runCardBlocked
    
    var id: String {
        switch self {
        case .cancel: return "cancel"
        case .changePINSuccessfully: return "changePINSuccessfully"
        case .runPINError(let remainingAttempts): return "runPINError (\(remainingAttempts))"
        case .runNFCError: return "runNFCError"
        case .askForCAN: return "askForCAN"
        case .runCardDeactivated: return "runCardDeactivated"
        case .runCardBlocked: return "runCardBlocked"
        }
    }
    
    static func defaultActions(card: Card) -> [ChangePINDebugSequence] {
        var actions: [ChangePINDebugSequence] = [
            .cancel,
            .changePINSuccessfully,
            .askForCAN,
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
            subject.send(.cardInteractionComplete)
            
            if card.remainingAttempts >= 2 {
                subject.send(.requestChangedPIN(remainingAttempts: nil, pinCallback: { _, _ in
                    subject.send(.requestCardInsertion({ _ in }))
                }))
                return ChangePINDebugSequence.defaultActions(card: card)
            } else if card.remainingAttempts == 1 {
                subject.send(.cardInteractionComplete)
                subject.send(.requestCANAndChangedPIN(pinCallback: { _, _, _ in
                    subject.send(.requestCardInsertion({ _ in }))
                }))
                return [
                    .cancel,
                    .changePINSuccessfully,
                    .askForCAN,
                    .runNFCError,
                    .runCardDeactivated,
                    .runCardBlocked
                ]
            } else {
                return []
            }
        case .changePINSuccessfully:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.processCompletedSuccessfullyWithoutRedirect)
            subject.send(completion: .finished)
            return []
        case .runPINError(remainingAttempts: let remainingAttempts):
            card.remainingAttempts = remainingAttempts - 1
            
            let secondCallback = {
                subject.send(.cardRemoved)
                subject.send(.requestCardInsertion({ _ in }))
            }
            
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
            
            if remainingAttempts >= 2 {
                subject.send(.requestChangedPIN(remainingAttempts: remainingAttempts, pinCallback: { _, _ in firstCallback() }))
                return [.changePINSuccessfully, .runPINError(remainingAttempts: card.remainingAttempts)]
            } else if card.remainingAttempts == 1 {
                subject.send(.requestCANAndChangedPIN(pinCallback: { _, _, _ in firstCallback() }))
                return [.changePINSuccessfully, .runPINError(remainingAttempts: card.remainingAttempts), .askForCAN]
            } else {
                subject.send(completion: .failure(.cardBlocked))
                return []
            }
        case .runNFCError:
            subject.send(completion: .failure(.processFailed(resultCode: .INTERNAL_ERROR, redirectURL: nil, resultMinor: nil)))
            return ChangePINDebugSequence.defaultActions(card: card)
        case .askForCAN:
            card.remainingAttempts = 1
            subject.send(.cardRecognized)
            subject.send(.cardInteractionComplete)
            subject.send(.requestCANAndChangedPIN { _, _, _ in
                subject.send(.requestCardInsertion { _ in })
            })
            subject.send(.cardRemoved)
            return [.cancel, .changePINSuccessfully, .askForCAN, .runPINError(remainingAttempts: card.remainingAttempts)]
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

#endif
