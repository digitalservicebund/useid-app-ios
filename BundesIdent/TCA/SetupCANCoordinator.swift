import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture
import Analytics

struct CANAndChangedPINCallbackPayload: Equatable {
    let can: String
    let oldPIN: String
    let newPIN: String
}

typealias CANAndChangedPINCallback = IdentifiableCallback<CANAndChangedPINCallbackPayload>

struct SetupCANCoordinator: ReducerProtocol {
    
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    
    struct State: Equatable, IndexedRouterState {
        
        var pin: String
        var transportPIN: String?
        var oldTransportPIN: String
        var canAndChangedPINCallback: CANAndChangedPINCallback
        var tokenURL: URL?
        
        var swipeToDismiss: SwipeToDismissState {
            guard let lastScreen = states.last?.screen else { return .allow }
            return lastScreen.swipeToDismissState
        }
        
#if PREVIEW
        var availableDebugActions: [ChangePINDebugSequence] = []
#endif
        var _shared: SharedCANCoordinator.State
        var states: [Route<SetupCANScreen.State>]
        
        typealias LocalAction = Action
        
        func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, IDCardInteractionError>) -> Action? {
            for (index, state) in states.enumerated().reversed() {
                guard let action = state.screen.transformToLocalAction(event) else { continue }
                return .routeAction(index, action: action)
            }
            return nil
        }
        
        var shared: SharedCANCoordinator.State {
            get {
                var value = _shared
                value.swipeToDismiss = swipeToDismiss
                return value
            }
            set {
                _shared = newValue
            }
        }
    }
    
    indirect enum Action: Equatable, IndexedRouterAction {
        case routeAction(Int, action: SetupCANScreen.Action)
        case updateRoutes([Route<SetupCANScreen.State>])
        case scanError(ScanError.State)
        case swipeToDismiss
        case afterConfirmEnd
        case dismissAlert
        case dismiss
        case shared(SharedCANCoordinator.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            guard case .routeAction(let index, action: .shared(let action)) = action else { return .none }
            let sharedEffect = SharedCANCoordinator().reduce(into: &state.shared, action: .routeAction(index, action: action))
            return sharedEffect.map(SetupCANCoordinator.Action.shared)
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .routeAction(_, action: .canConfirmTransportPIN(.confirm)):
                state.routes.push(.canAlreadySetup(.init(tokenURL: state.tokenURL)))
                return .none
            case .routeAction(_, action: .canConfirmTransportPIN(.edit)):
                state.routes.push(.shared(.canIntro(.init(shouldDismiss: false))))
                return .none
            case .routeAction(_, action: .canAlreadySetup(.missingPersonalPIN)):
                state.routes.push(.missingPIN(.init()))
                return .none
            case .routeAction(_, action: .shared(.canInput(.done(can: let can, pushesToPINEntry: let pushesToPINEntry)))):
                if pushesToPINEntry {
                    state.routes.push(.canTransportPINInput(.init(attempts: 1)))
                } else if let transportPIN = state.transportPIN {
                    state.routes.push(
                        .canScan(SetupCANScan.State(transportPIN: transportPIN,
                                                    newPIN: state.pin,
                                                    can: can,
                                                    canAndChangedPINCallback: state.canAndChangedPINCallback,
                                                    shared: SharedScan.State(showInstructions: false)))
                    )
                } else {
                    issueTracker.capture(error: SharedCANCoordinatorError.pinNilWhenTriedScan)
                    logger.error("Transport PIN or new PIN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                return .none
            case .routeAction(_, action: .canTransportPINInput(.done(transportPIN: let transportPIN))):
                state.transportPIN = transportPIN
                guard let can = state.shared.can else {
                    issueTracker.capture(error: SharedCANCoordinatorError.canNilWhenTriedScan)
                    logger.error("CAN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                state.routes.push(
                    .canScan(SetupCANScan.State(transportPIN: transportPIN,
                                                newPIN: state.pin,
                                                can: can,
                                                canAndChangedPINCallback: state.canAndChangedPINCallback,
                                                shared: SharedScan.State(showInstructions: false)))
                )
                
                return .none
            case .routeAction(_, action: .canScan(.incorrectCAN(callback: let callback))):
                state.canAndChangedPINCallback = callback
                state.routes.presentSheet(.shared(.canIncorrectInput(CANIncorrectInput.State())))
                return .none
            case .routeAction(_, action: .shared(.canIncorrectInput(.end))):
                guard let index = state.routes.firstIndex(where: { route in
                    if case .shared(.canIntro) = route.screen {
                        return true
                    }
                    return false
                }) else {
                    issueTracker.capture(error: SharedCANCoordinatorError.canIntroStateNotInRoutes)
                    logger.error("CanIntroState not found in routes")
                    return Effect(value: .dismiss)
                }
                return Effect.routeWithDelaysIfUnsupported(state.routes, scheduler: mainQueue) {
                    $0.dismiss()
                    $0.popTo(index: index)
                }
            case .routeAction(_, action: .canScan(.scannedSuccessfully)):
                let setupCoordinatorState = SetupCoordinator.State(tokenURL: state.tokenURL,
                                                                   states: [
                                                                       .root(.done(SetupDone.State(tokenURL: state.tokenURL)))
                                                                   ])
                state.routes.push(.setupCoordinator(setupCoordinatorState))
                return .none
            case .routeAction(_, action: .canScan(.error(let errorState))):
                state.routes.presentSheet(.shared(.scanError(errorState)))
                return .none
            case .routeAction(_, action: .canScan(.shared(.showHelp))):
                state.routes.presentSheet(.shared(.scanError(ScanError.State(errorType: .help, retry: true))))
                return .none
                
            case .shared(.afterConfirmEnd),
                 .routeAction(_, action: .canAlreadySetup(.done)),
                 .routeAction(_, action: .canScan(.dismiss)),
                 .routeAction(_, action: .setupCoordinator(.confirmEnd)),
                 .routeAction(_, action: .setupCoordinator(.routeAction(_, action: .done(.done)))),
                 .routeAction(_, action: .setupCoordinator(.afterConfirmEnd)):
                return Effect(value: .dismiss)
            case .shared(let action):
                switch action {
                case .push(let screenState):
                    state.routes.push(.shared(screenState))
                    return .none
                case .dismiss:
                    state.routes.dismiss()
                    return .none
                default:
                    let effect = SharedCANCoordinator().reduce(into: &state.shared, action: action)
                    return effect.map(Action.shared)
                }
            default:
                return .none
            }
        }.forEachRoute {
            SetupCANScreen()
        }
    }
}

extension SetupCANCoordinator.State: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}

extension SetupCANCoordinator.State {
    
    init(oldTransportPIN: String, transportPIN: String?, pin: String, callback: CANAndChangedPINCallback, attempt: Int, goToCanIntroScreen: Bool) {
        self.oldTransportPIN = oldTransportPIN
        self.transportPIN = transportPIN
        self.pin = pin
        canAndChangedPINCallback = callback
        _shared = .init(attempt: attempt)
        
        if goToCanIntroScreen {
            states = [.root(.shared(.canIntro(.init(shouldDismiss: true))))]
        } else {
            states = [
                .root(.canConfirmTransportPIN(SetupCANConfirmTransportPIN.State(transportPIN: oldTransportPIN)))
            ]
        }
    }
    
    var routes: [Route<SetupCANScreen.State>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .canScan(var state):
                        if let transportPIN {
                            state.transportPIN = transportPIN
                        }
                        if let can = shared.can {
                            state.can = can
                        }
                        state.newPIN = pin
                        state.shared.attempt = shared.attempt
                        state.canAndChangedPINCallback = canAndChangedPINCallback
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

struct SetupCANCoordinatorView: View {
    let store: StoreOf<SetupCANCoordinator>
    
    typealias State = SetupCANScreen.State
    typealias Action = SetupCANScreen.Action
    
    var body: some View {
        WithViewStore(store) { viewStore in
            TCARouter(store) { screen in
                SwitchStore(screen) {
                    CaseLet(state: /State.canConfirmTransportPIN,
                            action: Action.canConfirmTransportPIN,
                            then: SetupCANConfirmTransportPINView.init)
                    CaseLet(state: /State.canAlreadySetup,
                            action: Action.canAlreadySetup,
                            then: SetupCANAlreadySetupView.init)
                    CaseLet(state: /State.missingPIN,
                            action: Action.missingPIN,
                            then: MissingPINLetterView.init)
                    CaseLet(state: /State.canTransportPINInput,
                            action: Action.canTransportPINInput,
                            then: SetupTransportPINView.init)
                    CaseLet(state: /State.canScan,
                            action: Action.canScan,
                            then: SetupCANScanView.init)
                    CaseLet(state: /State.setupCoordinator,
                            action: Action.setupCoordinator,
                            then: SetupCoordinatorView.init)
                    CaseLet(state: /State.shared,
                            action: Action.shared,
                            then: SharedCANScreenView.init)
                }
            }
            .alert(store.scope(state: \.shared.alert, action: SetupCANCoordinator.Action.shared), dismiss: SharedCANCoordinator.Action.dismissAlert)
            .interactiveDismissDisabled(viewStore.swipeToDismiss != .allow) {
                viewStore.send(.swipeToDismiss)
            }
        }
    }
    
}

struct SharedCANScreenView: View {
    let store: StoreOf<SharedCANScreen>
    
    var body: some View {
        SwitchStore(store) {
            CaseLet(state: /SharedCANScreen.State.canIntro,
                    action: SharedCANScreen.Action.canIntro,
                    then: CANIntroView.init)
            CaseLet(state: /SharedCANScreen.State.canInput,
                    action: SharedCANScreen.Action.canInput,
                    then: CANInputView.init)
            CaseLet(state: /SharedCANScreen.State.canIncorrectInput,
                    action: SharedCANScreen.Action.canIncorrectInput,
                    then: CANIncorrectInputView.init)
            CaseLet(state: /SharedCANScreen.State.scanError,
                    action: SharedCANScreen.Action.error,
                    then: ScanErrorView.init)
        }
    }
}
