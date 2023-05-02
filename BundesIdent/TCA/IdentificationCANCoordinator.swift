import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture
import Analytics

enum IdentificationCANCoordinatorError: CustomNSError {
    case canNilWhenTriedScan
    case pinNilWhenTriedScan
    case canIntroStateNotInRoutes
    case pinCANCallbackNilWhenTriedScan
    case noScreenToHandleEIDInteractionEvents
}

struct IdentificationCANCoordinator: ReducerProtocol {
    
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    
    struct State: Equatable, IndexedRouterState {
        var pin: String?
        var can: String?
        var identificationInformation: IdentificationInformation
        var attempt: Int
        
        var swipeToDismiss: SwipeToDismissState {
            guard let lastScreen = states.last?.screen else { return .allow }
            return lastScreen.swipeToDismissState
        }
        
        var alert: AlertState<IdentificationCANCoordinator.Action>?
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        var states: [Route<IdentificationCANScreen.State>]
        
        func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, EIDInteractionError>) -> IdentificationCANCoordinator.Action? {
            for (index, state) in states.enumerated().reversed() {
                guard let action = state.screen.transformToLocalAction(event) else { continue }
                return .routeAction(index, action: action)
            }
            return nil
        }
    }
    
    enum Action: Equatable, IndexedRouterAction {
        case routeAction(Int, action: IdentificationCANScreen.Action)
        case updateRoutes([Route<IdentificationCANScreen.State>])
        case scanError(ScanError.State)
        case swipeToDismiss
        case afterConfirmEnd
        case dismissAlert
        case dismiss
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .routeAction(_, action: .canScan(.scanEvent(.success(.canRequested)))):
                state.routes.presentSheet(.canIncorrectInput(.init()))
                return .none
            case .routeAction(_, action: .canPINForgotten(.end)):
                return EffectTask(value: .swipeToDismiss)
            case .routeAction(_, action: .canPINForgotten(.orderNewPIN)):
                state.routes.push(.canOrderNewPIN(.init()))
                return .none
            case .routeAction(_, action: .canPINForgotten(.showCANIntro)):
                state.routes.push(.canIntro(CANIntro.State(shouldDismiss: false)))
                return .none
            case .routeAction(_, action: .canIntro(.showInput(let shouldDismiss))):
                state.routes.push(.canInput(CANInput.State(pushesToPINEntry: !shouldDismiss)))
                return .none
            case .routeAction(_, action: .canIntro(.end)):
                return EffectTask(value: .swipeToDismiss)
            case .routeAction(_, action: .canInput(.done(can: let can, pushesToPINEntry: let pushesToPINEntry))):
                state.can = can
                if pushesToPINEntry {
                    state.routes.push(.canPersonalPINInput(.init()))
                } else if let pin = state.pin {
                    state.routes.push(
                        .canScan(IdentificationCANScan.State(pin: pin,
                                                             can: can,
                                                             shared: SharedScan.State(startOnAppear: true)))
                    )
                } else {
                    issueTracker.capture(error: IdentificationCANCoordinatorError.pinNilWhenTriedScan)
                    logger.error("PIN nil when tried to scan")
                    return EffectTask(value: .dismiss)
                }
                return .none
            case .routeAction(_, action: .canPersonalPINInput(.done(pin: let pin))):
                state.pin = pin
                guard let can = state.can else {
                    issueTracker.capture(error: IdentificationCANCoordinatorError.canNilWhenTriedScan)
                    logger.error("CAN nil when tried to scan")
                    return EffectTask(value: .dismiss)
                }
                state.routes.push(
                    .canScan(IdentificationCANScan.State(pin: pin,
                                                         can: can,
                                                         shared: SharedScan.State(startOnAppear: true)))
                )
                
                return .none
            case .routeAction(_, action: .canIncorrectInput(.end)):
                guard let index = state.routes.firstIndex(where: { route in
                    if case .canIntro = route.screen {
                        return true
                    }
                    return false
                }) else {
                    issueTracker.capture(error: IdentificationCANCoordinatorError.canIntroStateNotInRoutes)
                    logger.error("CanIntroState not found in routes")
                    return EffectTask(value: .dismiss)
                }
                return EffectTask.routeWithDelaysIfUnsupported(state.routes, scheduler: mainQueue) {
                    $0.dismiss()
                    $0.popTo(index: index)
                }
            case .routeAction(_, action: .canIncorrectInput(.done(can: let can))):
                state.can = can
                state.attempt += 1
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .canScan(.shared(.showHelp))):
                state.routes.presentSheet(.error(ScanError.State(errorType: .help, retry: true)))
                return .none
            case .routeAction(_, action: .canScan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
                return .none
            case .routeAction(_, action: .error(.retry)):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .error(.end)):
                state.routes.dismiss()
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return EffectTask(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: mainQueue)
                    .eraseToEffect()
            case .swipeToDismiss:
                switch state.swipeToDismiss {
                case .allow:
                    return .none
                case .block:
                    return .none
                case .allowAfterConfirmation:
                    state.alert = AlertState.confirmEndInIdentification(.dismiss)
                    return .none
                }
            case .dismissAlert:
                state.alert = nil
                return .none
            default:
                return .none
            }
        }.forEachRoute {
            IdentificationCANScreen()
        }
    }
}

extension IdentificationCANCoordinator.State: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}

extension IdentificationCANCoordinator.State {
    init(identificationInformation: IdentificationInformation,
         pin: String?,
         attempt: Int,
         goToCanIntroScreen: Bool) {
        self.pin = pin
        self.identificationInformation = identificationInformation
        self.attempt = attempt
        if goToCanIntroScreen {
            states = [.root(.canIntro(.init(shouldDismiss: true)))]
        } else {
            states = [.root(.canPINForgotten(.init()))]
        }
    }
}

extension IdentificationCANCoordinator.State {
    var routes: [Route<IdentificationCANScreen.State>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .canScan(var state):
                        if let can {
                            state.can = can
                        }
                        if let pin {
                            state.pin = pin
                        }
                        state.shared.attempt = attempt
                        return .canScan(state)
                    default:
                        return screenState
                    }
                }
            }
        }
        set {
            states = newValue.map {
                $0.map { screenState in
                    switch screenState {
                    default:
                        break
                    }
                    return screenState
                }
            }
        }
    }
}

struct IdentificationCANCoordinatorView: View {
    let store: Store<IdentificationCANCoordinator.State, IdentificationCANCoordinator.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            TCARouter(store) { screen in
                SwitchStore(screen) {
                    CaseLet(state: /IdentificationCANScreen.State.error,
                            action: IdentificationCANScreen.Action.error,
                            then: ScanErrorView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canPINForgotten,
                            action: IdentificationCANScreen.Action.canPINForgotten,
                            then: IdentificationCANPINForgottenView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canOrderNewPIN,
                            action: IdentificationCANScreen.Action.orderNewPIN,
                            then: IdentificationCANOrderNewPINView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canIntro,
                            action: IdentificationCANScreen.Action.canIntro,
                            then: CANIntroView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canInput,
                            action: IdentificationCANScreen.Action.canInput,
                            then: CANInputView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canPersonalPINInput,
                            action: IdentificationCANScreen.Action.canPersonalPINInput,
                            then: IdentificationCANPersonalPINInputView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canIncorrectInput,
                            action: IdentificationCANScreen.Action.canIncorrectInput,
                            then: CANIncorrectInputView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canScan,
                            action: IdentificationCANScreen.Action.canScan,
                            then: IdentificationCANScanView.init)
                }
            }
            .alert(store.scope(state: \.alert), dismiss: IdentificationCANCoordinator.Action.dismissAlert)
            .interactiveDismissDisabled(viewStore.swipeToDismiss != .allow) {
                viewStore.send(IdentificationCANCoordinator.Action.swipeToDismiss)
            }
        }
    }
}
