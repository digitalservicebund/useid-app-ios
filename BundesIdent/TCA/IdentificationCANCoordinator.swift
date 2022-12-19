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
        var pinCANCallback: PINCANCallback
        var tokenURL: URL // TODO: IdentificationInformation
        var authenticationSuccessful = false
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
        
        func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationCANCoordinator.Action? {
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
    
    enum CancelId {}
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .routeAction(_, action: .canScan(.requestPINAndCAN(let request, let pinCANCallback))):
                state.pinCANCallback = pinCANCallback
                state.routes.presentSheet(.canIncorrectInput(.init(request: request)))
                return .none
            case .routeAction(_, action: .canPINForgotten(.end)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canPINForgotten(.orderNewPIN)):
                state.routes.push(.canOrderNewPIN(.init()))
                return .none
            case .routeAction(_, action: .canPINForgotten(.showCANIntro(let request))):
                state.routes.push(.canIntro(IdentificationCANIntro.State(request: request, shouldDismiss: false)))
                return .none
            case .routeAction(_, action: .canIntro(.showInput(let request, let shouldDismiss))):
                state.routes.push(.canInput(IdentificationCANInput.State(request: request, pushesToPINEntry: !shouldDismiss)))
                return .none
            case .routeAction(_, action: .canIntro(.end)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canInput(.done(can: let can, request: let request, pushesToPINEntry: let pushesToPINEntry))):
                state.can = can
                if pushesToPINEntry {
                    state.routes.push(.canPersonalPINInput(IdentificationCANPersonalPINInput.State(request: request)))
                } else if let pin = state.pin {
                    state.routes.push(
                        .canScan(IdentificationCANScan.State(request: request,
                                                             pin: pin,
                                                             can: can,
                                                             pinCANCallback: state.pinCANCallback,
                                                             shared: SharedScan.State(showInstructions: false)))
                    )
                } else {
                    issueTracker.capture(error: IdentificationCANCoordinatorError.pinNilWhenTriedScan)
                    logger.error("PIN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                return .none
            case .routeAction(_, action: .canPersonalPINInput(.done(pin: let pin, request: let request))):
                state.pin = pin
                guard let can = state.can else {
                    issueTracker.capture(error: IdentificationCANCoordinatorError.canNilWhenTriedScan)
                    logger.error("CAN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                state.routes.push(
                    .canScan(IdentificationCANScan.State(request: request,
                                                         pin: pin,
                                                         can: can,
                                                         pinCANCallback: state.pinCANCallback,
                                                         shared: SharedScan.State(showInstructions: false)))
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
                    return Effect(value: .dismiss)
                }
                
                return Effect.routeWithDelaysIfUnsupported(state.routes) {
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
                return Effect(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: mainQueue)
                    .eraseToEffect()
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
    init(tokenURL: URL,
         request: EIDAuthenticationRequest,
         pinCANCallback: PINCANCallback,
         pin: String?,
         attempt: Int,
         goToCanIntroScreen: Bool) {
        self.pin = pin
        self.pinCANCallback = pinCANCallback
        self.tokenURL = tokenURL
        self.attempt = attempt
        if goToCanIntroScreen {
            states = [.root(.canIntro(.init(request: request, shouldDismiss: true)))]
        } else {
            states = [.root(.canPINForgotten(.init(request: request)))]
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
                            then: IdentificationCANIntroView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canInput,
                            action: IdentificationCANScreen.Action.canInput,
                            then: IdentificationCANInputView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canPersonalPINInput,
                            action: IdentificationCANScreen.Action.canPersonalPINInput,
                            then: IdentificationCANPersonalPINInputView.init)
                    CaseLet(state: /IdentificationCANScreen.State.canIncorrectInput,
                            action: IdentificationCANScreen.Action.canIncorrectInput,
                            then: IdentificationCANIncorrectInputView.init)
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
