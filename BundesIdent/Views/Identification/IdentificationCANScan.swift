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
    @Dependency(\.uuid) var uuid
    @Dependency(\.idInteractionManager) var idInteractionManager
    
    struct State: Equatable, IDInteractionHandler {
        var pin: String
        var can: String
        var shared: SharedScan.State = .init()
        
        var lastRemainingAttempts: Int?
        var authenticationSuccessful = false
        var alert: AlertState<IdentificationCANScan.Action>?
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> Action? {
            .scanEvent(event)
        }
    }

    enum Action: Equatable {
        case onAppear
        case shared(SharedScan.Action)
        case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
        case wrongPIN(remainingAttempts: Int)
        case identifiedSuccessfully(redirectURL: URL)
        case error(ScanError.State)
        case cancelIdentification
        case dismiss
        case dismissAlert
#if PREVIEW
        case runDebugSequence(IdentifyDebugSequence)
#endif
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return state.shared.startOnAppear ? EffectTask(value: .shared(.startScan)) : .none
        case .shared(.startScan):
            idInteractionManager.setCAN(state.can)
            return .trackEvent(category: "identification",
                               action: "buttonPressed",
                               name: "canScan",
                               analytics: analytics)
        case .scanEvent(.success(let event)):
            return handle(state: &state, event: event)
        case .scanEvent(.failure(let error)):
            RedactedIDCardInteractionError(error).flatMap(issueTracker.capture(error:))
            
            switch error {
            case .cardDeactivated:
                return EffectTask(value: .error(ScanError.State(errorType: .cardDeactivated, retry: false)))
            case .cardBlocked:
                return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
            default:
                return EffectTask(value: .error(ScanError.State(errorType: .idCardInteraction(error), retry: false)))
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
            idInteractionManager.cancel()
            return .none
        case .dismissAlert:
            state.alert = nil
            return .none
        default:
            return .none
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<IdentificationCANScan.Action> {
        switch event {
        case .cardRecognized:
            logger.info("cardRecognized")
            return .none
        case .cardRemoved:
            logger.info("cardRemoved")
            return .none
        case .cardInsertionRequested:
            logger.info("cardInsertionRequested")
            return .none
        case .canRequested:
            idInteractionManager.interrupt()
            return .none
        case .pinRequested(remainingAttempts: let remainingAttempts):
            logger.info("pinRequested: \(String(describing: remainingAttempts))")
            state.shared.scanAvailable = true
            
            let lastRemainingAttempts = state.lastRemainingAttempts
            state.lastRemainingAttempts = remainingAttempts
            
            if let remainingAttempts,
               let lastRemainingAttempts,
               remainingAttempts < lastRemainingAttempts {
                idInteractionManager.interrupt()
                return EffectTask(value: .wrongPIN(remainingAttempts: remainingAttempts))
            } else {
                idInteractionManager.setPIN(state.pin)
                return .none
            }
        case .authenticationSucceeded(redirectUrl: .some(let redirectURL)):
            logger.info("Authentication successfully with redirect.")
            return EffectTask(value: .identifiedSuccessfully(redirectURL: redirectURL))
        case .authenticationSucceeded(redirectUrl: .none):
            issueTracker.capture(error: RedactedEIDInteractionEventError(.authenticationSucceeded(redirectUrl: nil)))
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: state.shared.scanAvailable)))
        case .pukRequested:
            return EffectTask(value: .scanEvent(.failure(.cardBlocked)))
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
                                                                                         can: "123456"),
                                               reducer: IdentificationCANScan()))
    }
}

#endif
