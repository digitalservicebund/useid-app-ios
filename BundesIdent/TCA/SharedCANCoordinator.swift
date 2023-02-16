import Foundation
import ComposableArchitecture

enum SharedCANCoordinatorError: CustomNSError {
    case canNilWhenTriedScan
    case pinNilWhenTriedScan
    case canIntroStateNotInRoutes
    case pinCANCallbackNilWhenTriedScan
    case noScreenToHandleEIDInteractionEvents
}

struct SharedCANCoordinator: ReducerProtocol {
    
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    
    struct State: Equatable {
        var pin: String?
        var can: String?
        var authenticationSuccessful = false
        var attempt: Int
        var alert: AlertState<Action>?
        var swipeToDismiss: SwipeToDismissState = .allow // TODO: Get from parent?
    }
    
    enum Action: Equatable {
        case swipeToDismiss
        case routeAction(Int, action: SharedCANScreen.Action)
        case push(SharedCANScreen.State)
        case dismiss
        case dismissAlert
        case afterConfirmEnd
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .routeAction(_, action: .canIntro(.showInput(let isRootOfCANFlow))):
                return Effect(value: .push(.canInput(CANInput.State(pushesToPINEntry: !isRootOfCANFlow))))
            case .routeAction(_, action: .canIntro(.end)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canIncorrectInput(.done(can: let newCAN))):
                state.can = newCAN
                state.attempt += 1
                return Effect(value: .dismiss)
            case .routeAction(_, action: .canInput(.done(can: let can, pushesToPINEntry: _))):
                state.can = can
                return .none
            case .routeAction(_, action: .error(.retry)):
                return Effect(value: .dismiss)
            case .routeAction(_, action: .error(.end)):
                return EffectTask.concatenate(
                    Effect(value: .dismiss),
                    // Dismissing two sheets at the same time from different coordinators is not well supported.
                    // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                    Effect(value: .afterConfirmEnd)
                        .delay(for: 0.65, scheduler: mainQueue)
                        .eraseToEffect()
                )
            case .swipeToDismiss:
                switch state.swipeToDismiss {
                case .allow:
                    return .none
                case .block:
                    return .none
                case .allowAfterConfirmation:
                    state.alert = AlertState(title: TextState(verbatim: L10n.Identification.ConfirmEnd.title),
                                             message: TextState(verbatim: L10n.Identification.ConfirmEnd.message),
                                             primaryButton: .destructive(TextState(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                                                         action: .send(.dismiss)),
                                             secondaryButton: .cancel(TextState(verbatim: L10n.Identification.ConfirmEnd.deny)))
                    return .none
                }
            case .dismissAlert:
                state.alert = nil
                return .none
            default:
                return .none
            }
        }
    }
}
