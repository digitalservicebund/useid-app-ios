import Analytics
import ComposableArchitecture
import FlowStacks
import Foundation
import IdentifiedCollections
import SwiftUI
import TCACoordinators

protocol IDInteractionHandler {
    associatedtype LocalAction
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> LocalAction?
}

enum SwipeToDismissState: Equatable {
    case block
    case allow
    case allowAfterConfirmation(title: String = L10n.Identification.ConfirmEnd.title,
                                body: String = L10n.Identification.ConfirmEnd.message,
                                confirm: String = L10n.Identification.ConfirmEnd.confirm,
                                deny: String = L10n.Identification.ConfirmEnd.deny)
}

enum IdentificationCoordinatorError: CustomNSError {
    case pinNilWhenTriedScan
    case noScreenToHandleEIDInteractionEvents
}

struct IdentificationCoordinator: ReducerProtocol {
    @Dependency(\.idInteractionManager) var idInteractionManager
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.storageManager) var storageManager
#if PREVIEW
    @Dependency(\.previewIDInteractionManager) var previewIDInteractionManager
#endif
    struct State: Equatable, IndexedRouterState {
        var identificationInformation: IdentificationInformation
        var pin: String?
        
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
        case back(identificationInformation: IdentificationInformation)
#if PREVIEW
        case runDebugSequence(IdentifyDebugSequence)
#endif
    }
    
    enum CancelId {}
    
    var body: some ReducerProtocol<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
#if PREVIEW
            case .runDebugSequence(let debugSequence):
                state.availableDebugActions = previewIDInteractionManager.runIdentify(debugSequence: debugSequence)
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
                return Effect(value: .back(identificationInformation: state.identificationInformation))
            case .routeAction(_, action: .overview(.loading(.identify))):
                let publisher: EIDInteractionPublisher
#if PREVIEW
                if previewIDInteractionManager.isDebugModeEnabled {
                    let debuggableInteraction = previewIDInteractionManager.debuggableIdentify(tokenURL: state.identificationInformation.tcTokenURL)
                    state.availableDebugActions = debuggableInteraction.sequence
                    publisher = debuggableInteraction.publisher
                } else {
                    publisher = idInteractionManager.identify(tokenURL: state.identificationInformation.tcTokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider())
                }
#else
                publisher = idInteractionManager.identify(tokenURL: state.identificationInformation.tcTokenURL, nfcMessagesProvider: IdentificationNFCMessageProvider())
#endif
                return publisher
                    .receive(on: mainQueue)
                    .catchToEffect(IdentificationCoordinator.Action.idInteractionEvent)
                    .cancellable(id: CancelId.self, cancelInFlight: true)
#if PREVIEW
            case .routeAction(_, action: .overview(.loading(.runDebugSequence(let sequence)))),
                 .routeAction(_, action: .scan(.runDebugSequence(let sequence))),
                 .routeAction(_, action: .identificationCANCoordinator(.routeAction(_, action: .canScan(.runDebugSequence(let sequence))))):
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
            case .routeAction(_, action: .scan(.error(let errorState))):
                state.routes.presentSheet(.error(errorState))
                return .none
            case .routeAction(_, action: .scan(.requestPINAndCAN(let request, let pinCANCallback))):
                let pinIsUnchecked = state.attempt == 0
                state.routes.push(.identificationCANCoordinator(.init(tokenURL: state.identificationInformation.tcTokenURL,
                                                                      request: request,
                                                                      pinCANCallback: pinCANCallback,
                                                                      pin: pinIsUnchecked ? state.pin : nil,
                                                                      attempt: state.attempt,
                                                                      goToCanIntroScreen: pinIsUnchecked)))
                return .none
            case .routeAction(_, action: .scan(.shared(.showHelp))):
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
            case .routeAction(_, action: .scan(.identifiedSuccessfully(let request, let redirectURL))):
                state.routes.push(
                    .handOff(IdentificationHandOff.State(identificationInformation: state.identificationInformation,
                                                         request: request,
                                                         redirectURL: redirectURL))
                )
                return .none
            case .routeAction(_, action: .handOff(.open(let request))):
                state.routes.push(.done(IdentificationDone.State(request: request)))
                return .none
            case .routeAction(_, action: .handOff(.refreshed(success: false, request: let request, redirectURL: let redirectURL))):
                state.routes.push(.share(IdentificationShare.State(request: request, redirectURL: redirectURL)))
                return .none
            case .routeAction(_, action: .handOff(.refreshed(success: true, request: let request, redirectURL: _))):
                state.routes.push(.done(IdentificationDone.State(request: request)))
                return .none
            case .routeAction(_, action: .share(.sent(success: true, request: let request))):
                state.routes.push(.done(IdentificationDone.State(request: request)))
                return .none
            case .swipeToDismiss:
                switch state.swipeToDismiss {
                case .allow:
                    return .none
                case .block:
                    return .none
                case .allowAfterConfirmation(let title, let message, let confirm, let deny):
                    state.alert = AlertState(title: TextState(verbatim: title),
                                             message: TextState(verbatim: message),
                                             primaryButton: .destructive(TextState(verbatim: confirm),
                                                                         action: .send(.dismiss)),
                                             secondaryButton: .cancel(TextState(verbatim: deny)))
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
                    case .identificationCANCoordinator(var canStates):
                        canStates.states = canStates.states.map {
                            $0.map { canScreenState in
                                switch canScreenState {
                                case .canScan(var state):
#if PREVIEW
                                    state.availableDebugActions = availableDebugActions
#endif
                                    return IdentificationCANScreen.State.canScan(state)
                                default:
                                    return canScreenState
                                }
                            }
                        }
                        return .identificationCANCoordinator(canStates)
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
    init(identificationInformation: IdentificationInformation, canGoBackToSetupIntro: Bool = false) {
        self.identificationInformation = identificationInformation
        states = [.root(.overview(.loading(IdentificationOverviewLoading.State(identificationInformation: identificationInformation, canGoBackToSetupIntro: canGoBackToSetupIntro))))]
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
                        CaseLet(state: /IdentificationScreen.State.identificationCANCoordinator,
                                action: IdentificationScreen.Action.identificationCANCoordinator,
                                then: IdentificationCANCoordinatorView.init)
                        CaseLet(state: /IdentificationScreen.State.handOff,
                                action: IdentificationScreen.Action.handOff,
                                then: IdentificationHandOffView.init)
                        CaseLet(state: /IdentificationScreen.State.done,
                                action: IdentificationScreen.Action.done,
                                then: IdentificationDoneView.init)
                        CaseLet(state: /IdentificationScreen.State.share,
                                action: IdentificationScreen.Action.share,
                                then: IdentificationShareView.init)
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
