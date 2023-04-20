import SwiftUI
import ComposableArchitecture
import Combine
import Sentry

enum IdentificationScanError: Error, Equatable, CustomNSError {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
    case cancelAfterCardRecognized
}

struct IdentificationPINScan: ReducerProtocol {
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.storageManager) var storageManager
    @Dependency(\.logger) var logger
    @Dependency(\.uuid) var uuid
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.idInteractionManager) var idInteractionManager
    
    struct State: Equatable, IDInteractionHandler {
        let authenticationInformation: AuthenticationInformation
        var pin: String
        var lastRemainingAttempts: Int?
        
        var shared: SharedScan.State = .init()
        
        var authenticationSuccessful = false
        var alert: AlertState<Action>?
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        var didAcceptAccessRights = false
        
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
        case requestCAN(AuthenticationInformation)
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
            guard !state.shared.showInstructions, !state.shared.isScanning else {
                return .none
            }
            return EffectTask(value: .shared(.startScan))
        case .shared(.startScan):
            state.shared.showInstructions = false
            state.shared.cardRecognized = false
            guard !state.shared.isScanning else { return .none }
            
            if state.didAcceptAccessRights {
                idInteractionManager.setPIN(state.pin)
            } else {
                state.didAcceptAccessRights = true
                idInteractionManager.acceptAccessRights()
            }
            
            state.shared.isScanning = true
            
            return .trackEvent(category: "identification",
                               action: "buttonPressed",
                               name: "scan",
                               analytics: analytics)
        case .scanEvent(.success(let event)):
            return handle(state: &state, event: event)
        case .scanEvent(.failure(let error)):
            RedactedIDCardInteractionError(error).flatMap(issueTracker.capture(error:))
            state.shared.isScanning = false
            switch error {
            case .cardDeactivated:
                return EffectTask(value: .error(ScanError.State(errorType: .cardDeactivated, retry: false)))
            case .cardBlocked:
                return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
            default:
                return EffectTask(value: .error(ScanError.State(errorType: .idCardInteraction(error), retry: false)))
            }
        case .wrongPIN:
            state.shared.isScanning = false
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
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<IdentificationPINScan.Action> {
        switch event {
        case .cardInsertionRequested:
            logger.info("cardInsertionRequested")
            return .none
        case .cardRemoved:
            logger.info("cardRemoved")
            return .none
        case .cardRecognized:
            logger.info("cardRecognized")
            return .none
        case .pinRequested(remainingAttempts: let remainingAttempts):
            logger.info("pinRequested: \(String(describing: remainingAttempts))")
            state.shared.isScanning = false
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
        case .canRequested:
            idInteractionManager.interrupt()
            return EffectTask(value: .requestCAN(state.authenticationInformation))
        case .pukRequested:
            return EffectTask(value: .scanEvent(.failure(.cardBlocked)))
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
        IdentificationPINScanView(store: Store(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                                         pin: "123456"),
                                               reducer: IdentificationPINScan()))
        IdentificationPINScanView(store: Store(initialState: IdentificationPINScan.State(authenticationInformation: .preview,
                                                                                         pin: "123456",
                                                                                         shared: SharedScan.State(isScanning: true)),
                                               reducer: IdentificationPINScan()))
    }
}

#endif
