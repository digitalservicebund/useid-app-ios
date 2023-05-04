import SwiftUI
import ComposableArchitecture
import Combine
import Sentry

struct IdentificationCANScan: ReducerProtocol {
    
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.storageManager) var storageManager
    @Dependency(\.logger) var logger
    @Dependency(\.eIDInteractionManager) var eIDInteractionManager
    
    struct State: Equatable, EIDInteractionHandler {
        var pin: String
        var can: String
        var identificationInformation: IdentificationInformation
        var shared: SharedScan.State = .init()
        
        var lastRemainingAttempts: Int?
        var alert: AlertState<IdentificationCANScan.Action>?
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        var shouldRestartAfterCancellation = false
        var shouldProvideCAN = false
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            .scanEvent(event)
        }
    }

    enum Action: Equatable {
        case onAppear
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case wrongPIN(remainingAttempts: Int)
        case wrongCAN
        case identifiedSuccessfully(redirectURL: URL)
        case error(ScanError.State)
        case cancelIdentification
        case dismiss
        case dismissAlert
        case restartAfterCancellation
#if PREVIEW
        case runDebugSequence(IdentifyDebugSequence)
#endif
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return state.shared.startOnAppear ? EffectTask(value: .shared(.startScan)) : .none
        case .shared(.startScan):
            if state.shouldRestartAfterCancellation {
                state.shouldRestartAfterCancellation = false
                return EffectTask(value: .restartAfterCancellation)
            } else {
                eIDInteractionManager.setCAN(state.can)
            }
            return .trackEvent(category: "identification",
                               action: "buttonPressed",
                               name: "canScan",
                               analytics: analytics)
        case .scanEvent(.success(let event)):
            return handle(state: &state, event: event)
        case .scanEvent(.failure(let error)):
            RedactedEIDInteractionError(error).flatMap(issueTracker.capture(error:))
            
            switch error {
            case .cardDeactivated:
                return EffectTask(value: .error(ScanError.State(errorType: .cardDeactivated, retry: false)))
            default:
                return EffectTask(value: .error(ScanError.State(errorType: .eIDInteraction(error), retry: false)))
            }
        case .wrongPIN:
            return .none
        case .identifiedSuccessfully(let redirectURL):
            storageManager.setupCompleted = true
            storageManager.identifiedOnce = true
            
            return .concatenate(.trackEvent(category: "identification", action: "success", analytics: analytics),
                                EffectTask(value: .dismiss),
                                .openURL(redirectURL, urlOpener: urlOpener))
        case .cancelIdentification:
            state.alert = AlertState.confirmEndInIdentification(.dismiss)
            return .none
        case .restartAfterCancellation:
            return .none
        case .dismiss:
            return .cancel(id: CancelId.self)
        case .dismissAlert:
            state.alert = nil
            return .none
        default:
            return .none
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<IdentificationCANScan.Action> {
        switch event {
        case .identificationStarted:
            logger.info("identificationStarted")
            state.shouldProvideCAN = true
            return .none
        case .cardRecognized:
            logger.info("cardRecognized")
            return .none
        case .cardInsertionRequested:
            logger.info("cardInsertionRequested")
            return .none
        case .canRequested:
            if state.shouldProvideCAN {
                state.shouldProvideCAN = false
                eIDInteractionManager.setCAN(state.can)
                return .none
            }
            eIDInteractionManager.interrupt()
            return .send(.wrongCAN)
        case .pinRequested(remainingAttempts: let remainingAttempts):
            logger.info("pinRequested: \(String(describing: remainingAttempts))")
            state.shared.scanAvailable = true
            
            let lastRemainingAttempts = state.lastRemainingAttempts
            state.lastRemainingAttempts = remainingAttempts
            
            if let remainingAttempts,
               let lastRemainingAttempts,
               remainingAttempts < lastRemainingAttempts {
                eIDInteractionManager.interrupt()
                return EffectTask(value: .wrongPIN(remainingAttempts: remainingAttempts))
            } else {
                eIDInteractionManager.setPIN(state.pin)
                return .none
            }
        case .identificationSucceeded(redirectURL: .some(let redirectURL)):
            logger.info("Identification successfully with redirect.")
            return EffectTask(value: .identifiedSuccessfully(redirectURL: redirectURL))
        case .identificationSucceeded(redirectURL: .none):
            issueTracker.capture(error: RedactedEIDInteractionEventError(.identificationSucceeded(redirectURL: nil)))
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: state.shared.scanAvailable)))
        case .identificationCancelled:
            state.shouldRestartAfterCancellation = true
            return .cancel(id: CancelId.self)
        case .identificationRequestConfirmationRequested(let request):
            
            // Equality check of the two attribute arrays is fine, as they are already sorted by the AusweisApp2
            guard state.identificationInformation.request == request else {
                issueTracker.capture(error: RedactedEIDInteractionError.identificationFailedWithRequestMismatch)
                logger.error("Old identification request and restartet one are not equal. Aborting identification.")
                return EffectTask(value: .error(ScanError.State(errorType: .identificationRequestMismatch,
                                                                retry: false)))
            }
            eIDInteractionManager.acceptAccessRights()
            return .none
        case .pukRequested:
            eIDInteractionManager.interrupt()
            return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
        default:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
    }
}

struct IdentificationCANScanView: View {
    
    var store: Store<IdentificationCANScan.State, IdentificationCANScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: IdentificationCANScan.Action.shared))
            .onAppear {
                ViewStore(store).send(.onAppear)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        ViewStore(store).send(.cancelIdentification)
                    }
                    .bodyLRegular(color: .accentColor)
                }
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: IdentificationCANScan.Action.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

#if DEBUG

struct IdentificationCANScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationCANScanView(store: Store(initialState: IdentificationCANScan.State(pin: "123456",
                                                                                         can: "123456",
                                                                                         identificationInformation: .preview),
                                               reducer: IdentificationCANScan()))
    }
}

#endif
