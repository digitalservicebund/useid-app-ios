import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture
import Analytics

protocol IDInteractionHandler {
    associatedtype LocalAction
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> LocalAction?
}

enum SwipeToDismissState {
    case block
    case allow
    case allowAfterConfirmation
}

enum IdentificationCoordinatorError: CustomNSError {
    case pinNilWhenTriedScan
    case canNilWhenTriedScan
    case canIntroStateNotInRoutes
    case noScreenToHandleEIDInteractionEvents
}

struct IdentificationCoordinator: ReducerProtocol {
    @Dependency(\.idInteractionManager) var idInteractionManager
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.storageManager) var storageManager
#if PREVIEW
    @Dependency(\.debugIDInteractionManager) var debugIDInteractionManager
#endif
    struct State: Equatable, IndexedRouterState {
        var tokenURL: URL
        var pin: String?
        var can: String?
        var attempt: Int = 0
        var authenticationSuccessful = false
        
        var swipeToDismiss: SwipeToDismissState {
            guard let lastScreen = states.last?.screen else { return .allow }
            return lastScreen.swipeToDismissState
        }
        
        var alert: AlertState<IdentificationCoordinator.Action>?
        
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        var states: [Route<IdentificationScreen.State>]
        
        func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationCoordinator.Action? {
            for (index, state) in states.enumerated().reversed() {
                guard let action = state.screen.transformToLocalAction(event) else { continue }
                return .routeAction(index, action: action)
            }
            return nil
        }
    }
    
    enum Action: Equatable, IndexedRouterAction {
        case routeAction(Int, action: IdentificationScreen.Action)
        case updateRoutes([Route<IdentificationScreen.State>])
        case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
        case scanError(ScanError.State)
        case swipeToDismiss
        case afterConfirmEnd
        case dismissAlert
        case dismiss
        case back(tokenURL: URL)
#if PREVIEW
        case runDebugSequence(IdentifyDebugSequence)
#endif
    }
    
    enum CancelId {}
    
    var body: some ReducerProtocol<State, Action> {
        return Reduce<State, Action> { state, action in
            switch action {
#if PREVIEW
            case .runDebugSequence(let debugSequence):
                state.availableDebugActions = debugIDInteractionManager.runIdentify(debugSequence: debugSequence)
                return .none
#endif
            case .routeAction(_, action: .scan(.wrongPIN(remainingAttempts: let remainingAttempts))):
                state.routes.presentSheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPIN.State(error: .incorrect,
                                                                                                         remainingAttempts: remainingAttempts)))
                return .none
            case .idInteractionEvent(let result):
                guard let localAction = state.transformToLocalInteractionHandler(event: result) else {
                    issueTracker.capture(error: IdentificationCoordinatorError.noScreenToHandleEIDInteractionEvents)
                    logger.error("No screen found to handle EIDInteractionEvents")
                    return .none
                }
                return Effect(value: localAction)
            case .routeAction(_, action: .incorrectPersonalPIN(.done(let pin))):
                state.pin = pin
                state.attempt += 1
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .overview(.back)):
                return Effect(value: .back(tokenURL: state.tokenURL))
            case .routeAction(_, action: .overview(.loading(.identify))):
                let publisher: EIDInteractionPublisher
#if PREVIEW
                if MOCK_OPENECARD {
                    let debuggableInteraction = debugIDInteractionManager.debuggableIdentify(tokenURL: state.tokenURL)
                    state.availableDebugActions = debuggableInteraction.sequence
                    publisher = debuggableInteraction.publisher
                } else {
                    publisher = idInteractionManager.identify(tokenURL: state.tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider())
                }
#else
                publisher = idInteractionManager.identify(tokenURL: state.tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider())
#endif
                return publisher
                    .receive(on: mainQueue)
                    .catchToEffect(IdentificationCoordinator.Action.idInteractionEvent)
                    .cancellable(id: CancelId.self, cancelInFlight: true)
#if PREVIEW
            case .routeAction(_, action: .overview(.loading(.runDebugSequence(let sequence)))),
                    .routeAction(_, action: .scan(.runDebugSequence(let sequence))),
                    .routeAction(_, action: .canScan(.runDebugSequence(let sequence))):
                return Effect(value: .runDebugSequence(sequence))
#endif
            case .routeAction(_, action: .overview(.loaded(.callbackReceived(let request, let callback)))):
                state.routes.push(.personalPIN(IdentificationPersonalPIN.State(request: request, callback: callback)))
                return .none
            case .routeAction(_, action: .personalPIN(.done(request: let request, pin: let pin, pinCallback: let pinCallback))):
                state.pin = pin
                state.routes.push(
                    .scan(IdentificationPINScan.State(request: request,
                                                      pin: pin,
                                                      pinCallback: pinCallback,
                                                      shared: SharedScan.State(showInstructions: !storageManager.identifiedOnce)))
                )
                return .none
            case .routeAction(_, action: .scan(.error(let errorState))),
                    .routeAction(_, action: .canScan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
                return .none
            case .routeAction(_, action: .scan(.requestPINAndCAN(let request, let pinCANCallback))):
                if state.attempt > 0 {
                    state.routes.push(.canPINForgotten(IdentificationCANPINForgotten.State(request: request, pinCANCallback: pinCANCallback)))
                } else {
                    return Effect.routeWithDelaysIfUnsupported(state.routes) {
                        $0.push(.canIntro(.init(request: request, pinCANCallback: pinCANCallback, shouldDismiss: true)))
                    }
                }
                return .none
            case .routeAction(_, action: .canScan(.requestPINAndCAN(let request, let pinCANCallback))):
                state.routes.presentSheet(.canIncorrectInput(.init(request: request, pinCANCallback: pinCANCallback)))
                return .none
            case .routeAction(_, action: .canPINForgotten(.end)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canPINForgotten(.orderNewPIN)):
                state.routes.push(.canOrderNewPIN(.init()))
                return .none
            case .routeAction(_, action: .canPINForgotten(.showCANIntro(let request, let pinCallback))):
                state.routes.push(.canIntro(IdentificationCANIntro.State(request: request, pinCANCallback: pinCallback, shouldDismiss: false)))
                return .none
            case .routeAction(_, action: .canIntro(.showInput(let request, let pinCallback, let shouldDismiss))):
                state.routes.push(.canInput(IdentificationCANInput.State(request: request, pinCANCallback: pinCallback, pushesToPINEntry: !shouldDismiss)))
                return .none
            case .routeAction(_, action: .canIntro(.end)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canInput(.done(can: let can, request: let request, pinCANCallback: let pinCANCallback, pushesToPINEntry: let pushesToPINEntry))):
                state.can = can
                if pushesToPINEntry {
                    state.routes.push(.canPersonalPINInput(IdentificationCANPersonalPINInput.State(request: request, pinCANCallback: pinCANCallback)))
                } else {
                    guard let pin = state.pin else {
                        issueTracker.capture(error: IdentificationCoordinatorError.pinNilWhenTriedScan)
                        logger.error("PIN nil when tried to scan")
                        return Effect(value: .dismiss)
                    }
                    state.routes.push(
                        .canScan(IdentificationCANScan.State(request: request,
                                                             pin: pin,
                                                             can: can,
                                                             pinCANCallback: pinCANCallback,
                                                             shared: SharedScan.State(showInstructions: false)))
                    )
                }
                
                return .none
            case .routeAction(_, action: .canPersonalPINInput(.done(pin: let pin, request: let request, pinCANCallback: let pinCANCallback))):
                state.pin = pin
                guard let can = state.can else {
                    issueTracker.capture(error: IdentificationCoordinatorError.canNilWhenTriedScan)
                    logger.error("CAN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                state.routes.push(
                    .canScan(IdentificationCANScan.State(request: request,
                                                         pin: pin,
                                                         can: can,
                                                         pinCANCallback: pinCANCallback,
                                                         shared: SharedScan.State(showInstructions: false)))
                )
                
                return .none
            case .routeAction(_, action: .canIncorrectInput(.end(_, let pinCANCallback))):
                let enumeratedRoutes = state.routes.enumerated()
                guard var (index, canIntroState) = enumeratedRoutes.reduce(nil, { partialResult, indexedRoute -> (Int, IdentificationCANIntro.State)? in
                    let route = indexedRoute.element
                    switch route.screen {
                    case .canIntro(let canIntroState): return (indexedRoute.offset, canIntroState)
                    default: return partialResult
                    }
                }) else {
                    issueTracker.capture(error: IdentificationCoordinatorError.canIntroStateNotInRoutes)
                    logger.error("CanIntroState not found in routes")
                    return Effect(value: .dismiss)
                }
                
                canIntroState.pinCANCallback = pinCANCallback
                state.routes[index].screen = .canIntro(canIntroState)
                
                return Effect.routeWithDelaysIfUnsupported(state.routes) {
                    $0.dismiss()
                    $0.popTo(index: index)
                }
            case .routeAction(_, action: .canIncorrectInput(.done(can: let can))):
                state.can = can
                state.attempt += 1
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .scan(.shared(.showHelp))), .routeAction(_, action: .canScan(.shared(.showHelp))):
                state.routes.presentSheet(.error(ScanError.State(errorType: .help, retry: true)))
                return .none
            case .routeAction(_, action: .error(.retry)):
                state.routes.dismiss()
                return .none
            case .routeAction(_, action: .error(.end)),
                    .routeAction(_, action: .incorrectPersonalPIN(.confirmEnd)):
                state.routes.dismiss()
                
                // Dismissing two sheets at the same time from different coordinators is not well supported.
                // Waiting for 0.65s (as TCACoordinators does) fixes this temporarily.
                return Effect(value: .afterConfirmEnd)
                    .delay(for: 0.65, scheduler: mainQueue)
                    .eraseToEffect()
                
            case .routeAction(_, action: .overview(.end)):
                state.alert = AlertState(title: TextState(verbatim: L10n.Identification.ConfirmEnd.title),
                                         message: TextState(verbatim: L10n.Identification.ConfirmEnd.message),
                                         primaryButton: .destructive(TextState(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                                                     action: .send(.dismiss)),
                                         secondaryButton: .cancel(TextState(verbatim: L10n.Identification.ConfirmEnd.deny)))
                return .none
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
            IdentificationScreen()
        }
    }
    
}

extension IdentificationCoordinator.State {
    var routes: [Route<IdentificationScreen.State>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .overview(var state):
#if PREVIEW
                        state.availableDebugActions = availableDebugActions
#endif
                        return .overview(state)
                    case .scan(var state):
                        if let pin {
                            state.pin = pin
                        }
                        
                        state.shared.attempt = attempt
#if PREVIEW
                        state.availableDebugActions = availableDebugActions
#endif
                        return .scan(state)
                    case .canScan(var state):
                        if let can, let pin {
                            state.can = can
                            state.pin = pin
                        }
                        
                        state.shared.attempt = attempt
#if PREVIEW
                        state.availableDebugActions = availableDebugActions
#endif
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

extension IdentificationCoordinator.State: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}

extension IdentificationCoordinator.State {
    init(tokenURL: URL, canGoBackToSetupIntro: Bool = false) {
        self.tokenURL = tokenURL
        self.states = [.root(.overview(.loading(IdentificationOverviewLoading.State(canGoBackToSetupIntro: canGoBackToSetupIntro))))]
    }
}

/*
 Happy path loading token until scanning:
 .authenticationStarted
 .requestAuthenticationRequestConfirmation
 .cardInteractionComplete
 .requestPIN(remainingAttempts: nil)
 .requestCardInsertion
 
 Happy path identification:
 .cardRecognized
 .authenticationSuccessful
 .processCompletedSuccessfully
 
 Wrong pin identification:
 .cardRecognized
 .cardInteractionComplete
 .requestPIN(remainingAttempts: 3)
 .cardRemoved
 
 Card removed before process finished:
 .cardRecognized
 .authenticationSuccessful (optional)
 .cardRemoved // difference from happy path?
 .processCompletedSuccessfully // not really successful
 
 Wrong card:
 .cardInteractionComplete
 .requestPIN(remainingAttempts: nil) // like cancel
 */

struct IdentificationCoordinatorView: View {
    let store: Store<IdentificationCoordinator.State, IdentificationCoordinator.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                TCARouter(store) { screen in
                    SwitchStore(screen) {
                        CaseLet(state: /IdentificationScreen.State.overview,
                                action: IdentificationScreen.Action.overview,
                                then: IdentificationOverviewView.init)
                        CaseLet(state: /IdentificationScreen.State.personalPIN,
                                action: IdentificationScreen.Action.personalPIN,
                                then: IdentificationPersonalPINView.init)
                        CaseLet(state: /IdentificationScreen.State.incorrectPersonalPIN,
                                action: IdentificationScreen.Action.incorrectPersonalPIN,
                                then: IdentificationIncorrectPersonalPINView.init)
                        CaseLet(state: /IdentificationScreen.State.scan,
                                action: IdentificationScreen.Action.scan,
                                then: IdentificationPINScanView.init)
                        CaseLet(state: /IdentificationScreen.State.error,
                                action: IdentificationScreen.Action.error,
                                then: ScanErrorView.init)
                        CaseLet(state: /IdentificationScreen.State.canPINForgotten,
                                action: IdentificationScreen.Action.canPINForgotten,
                                then: IdentificationCANPINForgottenView.init)
                        CaseLet(state: /IdentificationScreen.State.canOrderNewPIN,
                                action: IdentificationScreen.Action.orderNewPIN,
                                then: IdentificationCANOrderNewPINView.init)
                        CaseLet(state: /IdentificationScreen.State.canIntro,
                                action: IdentificationScreen.Action.canIntro,
                                then: IdentificationCANIntroView.init)
                        CaseLet(state: /IdentificationScreen.State.canInput,
                                action: IdentificationScreen.Action.canInput,
                                then: IdentificationCANInputView.init)
                        Default {
                            SwitchStore(screen) {
                                CaseLet(state: /IdentificationScreen.State.canPersonalPINInput,
                                        action: IdentificationScreen.Action.canPersonalPINInput,
                                        then: IdentificationCANPersonalPINInputView.init)
                                CaseLet(state: /IdentificationScreen.State.canIncorrectInput,
                                        action: IdentificationScreen.Action.canIncorrectInput,
                                        then: IdentificationCANIncorrectInputView.init)
                                CaseLet(state: /IdentificationScreen.State.canScan,
                                        action: IdentificationScreen.Action.canScan,
                                        then: IdentificationCANScanView.init)
                            }
                        }
                    }
                }
            }
            .accentColor(Asset.accentColor.swiftUIColor)
            .ignoresSafeArea(.keyboard)
            .alert(store.scope(state: \.alert), dismiss: IdentificationCoordinator.Action.dismissAlert)
            .interactiveDismissDisabled(viewStore.swipeToDismiss != .allow) {
                viewStore.send(IdentificationCoordinator.Action.swipeToDismiss)
            }
        }
    }
}
