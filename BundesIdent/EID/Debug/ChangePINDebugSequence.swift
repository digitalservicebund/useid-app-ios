import Foundation
import Combine

#if PREVIEW

enum ChangePINDebugSequence: Identifiable, Equatable {
    case cancelPINScan
    case cancelCANScan
    case changePINSuccessfully
    case runPINError(remainingAttempts: Int, cancelAction: CancelAction)
    case runNFCError
    case runCardSuspended
    case runCardDeactivated
    case runCardBlocked
    case runCANError
    
    var id: String {
        switch self {
        case .cancelPINScan: return "cancel"
        case .cancelCANScan: return "cancel"
        case .changePINSuccessfully: return "changePINSuccessfully"
        case .runPINError(let remainingAttempts, _): return "runPINError (\(remainingAttempts))"
        case .runNFCError: return "runNFCError"
        case .runCardSuspended: return "runCardSuspended"
        case .runCardDeactivated: return "runCardDeactivated"
        case .runCardBlocked: return "runCardBlocked"
        case .runCANError: return "runCANError"
        }
    }
    
    static func defaultActions(card: Card) -> [ChangePINDebugSequence] {
        var actions: [ChangePINDebugSequence] = [
            .cancelPINScan,
            .changePINSuccessfully,
            .runCardSuspended,
            .runNFCError,
            .runCardDeactivated,
            .runCardBlocked
        ]
        
        if card.remainingAttempts >= 0 {
            actions.append(.runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .pin))
        }
        
        return actions
    }
    
    func run(card: inout Card, subject: PassthroughSubject<EIDInteractionEvent, EIDInteractionError>) -> [ChangePINDebugSequence] {
        switch self {
        case .cancelPINScan:
            subject.send(.pinRequested(remainingAttempts: nil))
            subject.send(.newPINRequested)
            subject.send(.cardInsertionRequested)
            return ChangePINDebugSequence.defaultActions(card: card)
        case .cancelCANScan:
            subject.send(.canRequested)
            subject.send(.cardInsertionRequested)
            return [
                .cancelCANScan,
                .changePINSuccessfully,
                .runCANError,
                .runNFCError,
                .runCardDeactivated,
                .runCardBlocked
            ]
        case .changePINSuccessfully:
            card.remainingAttempts = 3
            subject.send(.cardRecognized)
            subject.send(.pinChangeSucceeded)
            subject.send(completion: .finished)
            return []
        case .runPINError(remainingAttempts: let remainingAttempts, cancelAction: let cancelAction):
            card.remainingAttempts = remainingAttempts - 1
            
            subject.send(.cardRecognized)
            
            let cancelDebugSequence: ChangePINDebugSequence
            switch cancelAction {
            case .pin: cancelDebugSequence = .cancelPINScan
            case .can: cancelDebugSequence = .cancelCANScan
            }
            
            if card.remainingAttempts >= 2 {
                subject.send(.pinRequested(remainingAttempts: remainingAttempts))
                subject.send(.newPINRequested)
                subject.send(.cardInsertionRequested)
                subject.send(.cardRecognized)
                subject.send(.pinRequested(remainingAttempts: card.remainingAttempts))
                subject.send(.cardInsertionRequested)
                return [.changePINSuccessfully, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: cancelAction), cancelDebugSequence]
            } else if card.remainingAttempts == 1 {
                subject.send(.canRequested)
                return [.changePINSuccessfully, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: cancelAction), .runCANError, cancelDebugSequence]
            } else {
                subject.send(.pukRequested)
                return []
            }
        case .runNFCError:
            subject.send(completion: .failure(.pinChangeFailed))
            return ChangePINDebugSequence.defaultActions(card: card)
        case .runCardSuspended:
            card.remainingAttempts = 1
            subject.send(.canRequested)
            return [.cancelCANScan, .changePINSuccessfully, .runCANError, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .can)]
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
            subject.send(.canRequested)
            subject.send(.cardInsertionRequested)
            return [.cancelCANScan, .changePINSuccessfully, .runCANError, .runPINError(remainingAttempts: card.remainingAttempts, cancelAction: .can)]
        }
    }
}

#endif
