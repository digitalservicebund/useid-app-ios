import SwiftUI
import ComposableArchitecture
import Combine
import Sentry

enum IdentificationScanError: Error, Equatable, CustomNSError {
    case eIDInteraction(EIDInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
    case cancelAfterCardRecognized
}

struct IdentificationPINScan: ReducerProtocol {
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.storageManager) var storageManager
    @Dependency(\.logger) var logger
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.eIDInteractionManager) var eIDInteractionManager
    
    struct State: Equatable, EIDInteractionHandler {
        let identificationInformation: IdentificationInformation
        var pin: String
        var lastRemainingAttempts: Int?
        
        var shared: SharedScan.State = .init()
        
        var alert: AlertState<Action>?
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        var didAcceptAccessRights = false
        var shouldRestartAfterCancellation = false
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            .scanEvent(event)
        }
    }
    
    enum Action: Equatable {
        case onAppear
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case wrongPIN(remainingAttempts: Int)
        case identifiedSuccessfully(redirectURL: URL)
        case requestCAN(IdentificationInformation)
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
            state.shared.startOnAppear = true
            state.shared.cardRecognized = false

            if state.shouldRestartAfterCancellation {
                state.shouldRestartAfterCancellation = false
                return EffectTask(value: .restartAfterCancellation)
            } else if state.didAcceptAccessRights {
                eIDInteractionManager.setPIN(state.pin)
            } else {
                state.didAcceptAccessRights = true
                eIDInteractionManager.acceptAccessRights()
            }

            return .trackEvent(category: "identification",
                               action: "buttonPressed",
                               name: "scan",
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
        case .dismiss:
            return .cancel(id: CancelId.self)
        case .dismissAlert:
            state.alert = nil
            return .none
        default:
            return .none
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<IdentificationPINScan.Action> {
        switch event {
        case .identificationStarted:
            logger.info("Silent identification started after cancellation.")
            return .none
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
        case .cardInsertionRequested:
            logger.info("cardInsertionRequested")
            return .none
        case .cardRecognized:
            logger.info("cardRecognized")
            return .none
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
        case .canRequested:
            eIDInteractionManager.interrupt()
            return EffectTask(value: .requestCAN(state.identificationInformation))
                .delay(for: 2, scheduler: mainQueue) // this delay is here to fix a bug where this particular screen was presented incorrectly
                .eraseToEffect()
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

struct IdentificationPINScanView: View {
    
    var store: Store<IdentificationPINScan.State, IdentificationPINScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: IdentificationPINScan.Action.shared))
            .onAppear {
                ViewStore(store).send(.onAppear)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        ViewStore(store).send(.cancelIdentification)
                    }
                }
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: IdentificationPINScan.Action.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

#if DEBUG

struct IdentificationScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationPINScanView(store: Store(initialState: IdentificationPINScan.State(identificationInformation: .preview,
                                                                                         pin: "123456"),
                                               reducer: IdentificationPINScan()))
    }
}

#endif
