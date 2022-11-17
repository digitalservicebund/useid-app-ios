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

struct IdentificationCoordinatorState: Equatable, IndexedRouterState {
    var tokenURL: URL
    var pin: String?
    var can: String?
    var attempt: Int = 0
    var authenticationSuccessful = false
    
    var swipeToDismiss: SwipeToDismissState {
        guard let lastScreen = states.last?.screen else { return .allow }
        return lastScreen.swipeToDismissState
    }
    
    var alert: AlertState<IdentificationCoordinatorAction>?

#if PREVIEW
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    
    var routes: [Route<IdentificationScreenState>] {
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
    var states: [Route<IdentificationScreenState>]
    
    func transformToLocalInteractionHandler(event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationCoordinatorAction? {
        for (index, state) in states.enumerated().reversed() {
            guard let action = state.screen.transformToLocalAction(event) else { continue }
            return .routeAction(index, action: action)
        }
        return nil
    }
}

extension IdentificationCoordinatorState: AnalyticsView {
    var route: [String] {
        states.last?.screen.route ?? []
    }
}

extension IdentificationCoordinatorState {
    init(tokenURL: URL, canGoBackToSetupIntro: Bool = false) {
        self.tokenURL = tokenURL
        self.states = [.root(.overview(.loading(IdentificationOverviewLoadingState(canGoBackToSetupIntro: canGoBackToSetupIntro))))]
    }
}

enum IdentificationCoordinatorAction: Equatable, IndexedRouterAction {
    case routeAction(Int, action: IdentificationScreenAction)
    case updateRoutes([Route<IdentificationScreenState>])
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case scanError(ScanErrorState)
    case swipeToDismiss
    case afterConfirmEnd
    case dismissAlert
    case dismiss
    case back(tokenURL: URL)
#if PREVIEW
    case runDebugSequence(IdentifyDebugSequence)
#endif
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

let identificationCoordinatorReducer: Reducer<IdentificationCoordinatorState, IdentificationCoordinatorAction, AppEnvironment> = identificationScreenReducer
    .forEachIndexedRoute(environment: { $0 })
    .withRouteReducer(
        Reducer { state, action, environment in
            enum CancelId {}
            
            switch action {
#if PREVIEW
            case .runDebugSequence(let debugSequence):
                state.availableDebugActions = environment.debugIDInteractionManager.runIdentify(debugSequence: debugSequence)
                return .none
#endif
            case .routeAction(_, action: .scan(.wrongPIN(remainingAttempts: let remainingAttempts))):
                state.routes.presentSheet(.incorrectPersonalPIN(IdentificationIncorrectPersonalPINState(error: .incorrect,
                                                                                                        remainingAttempts: remainingAttempts)))
                return .none
            case .idInteractionEvent(let result):
                guard let localAction = state.transformToLocalInteractionHandler(event: result) else {
                    environment.issueTracker.capture(error: IdentificationCoordinatorError.noScreenToHandleEIDInteractionEvents)
                    environment.logger.error("No screen found to handle EIDInteractionEvents")
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
                    let debuggableInteraction = environment.debugIDInteractionManager.debuggableIdentify(tokenURL: state.tokenURL)
                    state.availableDebugActions = debuggableInteraction.sequence
                    publisher = debuggableInteraction.publisher
                } else {
                    publisher = environment.idInteractionManager.identify(tokenURL: state.tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider())
                }
#else
                publisher = environment.idInteractionManager.identify(tokenURL: state.tokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider())
#endif
                return publisher
                    .receive(on: environment.mainQueue)
                    .catchToEffect(IdentificationCoordinatorAction.idInteractionEvent)
                    .cancellable(id: CancelId.self, cancelInFlight: true)
#if PREVIEW
            case .routeAction(_, action: .overview(.loading(.runDebugSequence(let sequence)))),
                    .routeAction(_, action: .scan(.runDebugSequence(let sequence))),
                    .routeAction(_, action: .canScan(.runDebugSequence(let sequence))):
                return Effect(value: .runDebugSequence(sequence))
#endif
            case .routeAction(_, action: .overview(.loaded(.callbackReceived(let request, let callback)))):
                state.routes.push(.personalPIN(IdentificationPersonalPINState(request: request, callback: callback)))
                return .none
            case .routeAction(_, action: .personalPIN(.done(request: let request, pin: let pin, pinCallback: let pinCallback))):
                state.pin = pin
                state.routes.push(
                    .scan(IdentificationScanState(request: request,
                                                  pin: pin,
                                                  pinCallback: pinCallback,
                                                  shared: SharedScanState(showInstructions: !environment.storageManager.identifiedOnce)))
                )
                return .none
            case .routeAction(_, action: .scan(.error(let errorState))),
                    .routeAction(_, action: .canScan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
                return .none
            case .routeAction(_, action: .scan(.requestPINAndCAN(let request, let pinCANCallback))):
                if state.attempt > 0 {
                    state.routes.push(.canPINForgotten(IdentificationCANPINForgottenState(request: request, pinCANCallback: pinCANCallback)))
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
                state.routes.push(.canIntro(IdentificationCANIntroState(request: request, pinCANCallback: pinCallback, shouldDismiss: false)))
                return .none
            case .routeAction(_, action: .canIntro(.showInput(let request, let pinCallback, let shouldDismiss))):
                state.routes.push(.canInput(IdentificationCANInputState(request: request, pinCANCallback: pinCallback, pushesToPINEntry: !shouldDismiss)))
                return .none
            case .routeAction(_, action: .canIntro(.end)):
                return Effect(value: .swipeToDismiss)
            case .routeAction(_, action: .canInput(.done(can: let can, request: let request, pinCANCallback: let pinCANCallback, pushesToPINEntry: let pushesToPINEntry))):
                state.can = can
                if pushesToPINEntry {
                    state.routes.push(.canPersonalPINInput(IdentificationCANPersonalPINInputState(request: request, pinCANCallback: pinCANCallback)))
                } else {
                    guard let pin = state.pin else {
                        environment.issueTracker.capture(error: IdentificationCoordinatorError.pinNilWhenTriedScan)
                        environment.logger.error("PIN nil when tried to scan")
                        return Effect(value: .dismiss)
                    }
                    state.routes.push(
                        .canScan(IdentificationCANScanState(request: request,
                                                            pin: pin,
                                                            can: can,
                                                            pinCANCallback: pinCANCallback,
                                                            shared: SharedScanState(showInstructions: false)))
                    )
                }
                
                return .none
            case .routeAction(_, action: .canPersonalPINInput(.done(pin: let pin, request: let request, pinCANCallback: let pinCANCallback))):
                state.pin = pin
                guard let can = state.can else {
                    environment.issueTracker.capture(error: IdentificationCoordinatorError.canNilWhenTriedScan)
                    environment.logger.error("CAN nil when tried to scan")
                    return Effect(value: .dismiss)
                }
                state.routes.push(
                    .canScan(IdentificationCANScanState(request: request,
                                                        pin: pin,
                                                        can: can,
                                                        pinCANCallback: pinCANCallback,
                                                        shared: SharedScanState(showInstructions: false)))
                )
                
                return .none
            case .routeAction(_, action: .canIncorrectInput(.end(let request, let pinCANCallback))):
                state.routes.dismiss()
                guard let index = state.routes.lastIndex(where: { state in
                    if case .canIntro = state.screen {
                        return true
                    } else {
                        return false
                    }
                }) else {
                    environment.issueTracker.capture(error: IdentificationCoordinatorError.canIntroStateNotInRoutes)
                    environment.logger.error("CanIntroState not found in routes")
                    return Effect(value: .dismiss)
                }
                state.routes.popTo(index: index)
                return .none
            case .routeAction(_, action: .canIncorrectInput(.done(can: let can))):
                state.routes.dismiss()
                state.can = can
                state.attempt += 1
                return .none
            case .routeAction(_, action: .scan(.shared(.showHelp))), .routeAction(_, action: .canScan(.shared(.showHelp))):
                state.routes.presentSheet(.error(ScanErrorState(errorType: .help, retry: true)))
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
                    .delay(for: 0.65, scheduler: environment.mainQueue)
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
        }
    )

struct IdentificationCoordinatorView: View {
    let store: Store<IdentificationCoordinatorState, IdentificationCoordinatorAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            NavigationView {
                TCARouter(store) { screen in
                    SwitchStore(screen) {
                        CaseLet(state: /IdentificationScreenState.overview,
                                action: IdentificationScreenAction.overview,
                                then: IdentificationOverview.init)
                        CaseLet(state: /IdentificationScreenState.personalPIN,
                                action: IdentificationScreenAction.personalPIN,
                                then: IdentificationPersonalPIN.init)
                        CaseLet(state: /IdentificationScreenState.incorrectPersonalPIN,
                                action: IdentificationScreenAction.incorrectPersonalPIN,
                                then: IdentificationIncorrectPersonalPIN.init)
                        CaseLet(state: /IdentificationScreenState.scan,
                                action: IdentificationScreenAction.scan,
                                then: IdentificationScan.init)
                        CaseLet(state: /IdentificationScreenState.error,
                                action: IdentificationScreenAction.error,
                                then: ScanError.init)
                        CaseLet(state: /IdentificationScreenState.canPINForgotten,
                                action: IdentificationScreenAction.canPINForgotten,
                                then: IdentificationCANPINForgotten.init)
                        CaseLet(state: /IdentificationScreenState.canOrderNewPIN,
                                action: IdentificationScreenAction.orderNewPIN,
                                then: IdentificationCANOrderNewPIN.init)
                        CaseLet(state: /IdentificationScreenState.canIntro,
                                action: IdentificationScreenAction.canIntro,
                                then: IdentificationCANIntro.init)
                        CaseLet(state: /IdentificationScreenState.canInput,
                                action: IdentificationScreenAction.canInput,
                                then: IdentificationCANInput.init)
                        Default {
                            SwitchStore(screen) {
                                CaseLet(state: /IdentificationScreenState.canPersonalPINInput,
                                        action: IdentificationScreenAction.canPersonalPINInput,
                                        then: IdentificationCANPersonalPINInput.init)
                                CaseLet(state: /IdentificationScreenState.canIncorrectInput,
                                        action: IdentificationScreenAction.canIncorrectInput,
                                        then: IdentificationCANIncorrectInput.init)
                                CaseLet(state: /IdentificationScreenState.canScan,
                                        action: IdentificationScreenAction.canScan,
                                        then: IdentificationCANScan.init)
                            }
                        }
                    }
                }
            }
            .accentColor(Asset.accentColor.swiftUIColor)
            .ignoresSafeArea(.keyboard)
            .alert(store.scope(state: \.alert), dismiss: IdentificationCoordinatorAction.dismissAlert)
            .interactiveDismissDisabled(viewStore.swipeToDismiss != .allow) {
                viewStore.send(IdentificationCoordinatorAction.swipeToDismiss)
            }
        }
    }
}
