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
        
        enum WorkflowState {
            case shouldAccept
            case setPin
        }

        var workflowState: WorkflowState = .shouldAccept
        
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
        case requestPINAndCAN(EIDAuthenticationRequest, PINCANCallback)
        case requestCAN(EIDAuthenticationRequest, PINCallback)
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
            
            switch state.workflowState {
            case .shouldAccept: idInteractionManager.acceptAccessRights()
            case .setPin: idInteractionManager.setPIN(state.pin)
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
        case .shared(.showNFCInfo):
            state.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                     message: TextState(L10n.HelpNFC.body),
                                     dismissButton: .cancel(TextState(L10n.General.ok),
                                                            action: .send(.dismissAlert)))
            
            return .trackEvent(category: "identification",
                               action: "alertShown",
                               name: "NFCInfo",
                               analytics: analytics)
        case .cancelIdentification:
            state.alert = AlertState.confirmEndInIdentification(.dismiss)
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
            state.workflowState = .setPin
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
        case .authenticationSucceeded(redirectUrl: .some(let redirectUrl)):
            logger.info("Authentication successfully with redirect.")
            return EffectTask(value: .identifiedSuccessfully(redirectURL: redirectUrl))
        case .authenticationSucceeded(redirectUrl: .none):
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: state.shared.scanAvailable)))
        case .canRequested:
            idInteractionManager.cancel()
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
//        case .requestPINAndCAN(let callback):
//            let callbackId = uuid.callAsFunction()
//            let pinCANCallback = PINCANCallback(id: callbackId, callback: callback)
//            logger.info("PIN and CAN request: \(callbackId)")
//            state.shared.isScanning = false
//            state.shared.scanAvailable = true
//            return EffectTask(value: .requestPINAndCAN(state.request, pinCANCallback))
//                .delay(for: 2, scheduler: mainQueue) // this delay is here to fix a bug where this particular screen was presented incorrectly
//                .eraseToEffect()
//        case .authenticationStarted:
//            logger.info("Authentication started.")
//            state.shared.isScanning = true
//        case .cardInteractionComplete:
//            logger.info("Card interaction complete.")
//        case .requestCardInsertion:
//            state.shared.isScanning = true
//        case .cardRecognized:
//            logger.info("Card recognized.")
//            state.shared.cardRecognized = true
//            state.shared.isScanning = true
//        case .authenticationSuccessful:
//            logger.info("Authentication succesful.")
//            state.shared.isScanning = true
//            state.authenticationSuccessful = true
//        case .cardRemoved:
//            logger.info("Card removed.")
//            state.authenticationSuccessful = false
//        case .processCompletedSuccessfullyWithRedirect(let redirect):
//            logger.info("Authentication successfully with redirect.")
//            return EffectTask(value: .identifiedSuccessfully(redirectURL: redirect))
//        case .processCompletedSuccessfullyWithoutRedirect:
//            state.shared.scanAvailable = false
//            issueTracker.capture(error: RedactedEIDInteractionEventError(.processCompletedSuccessfullyWithoutRedirect))
//            logger.error("Received unexpected event.")
//            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(.processCompletedSuccessfullyWithoutRedirect), retry: state.shared.scanAvailable)))
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
        SharedScanView(store: store.scope(state: \.shared, action: IdentificationPINScan.Action.shared),
                       instructionsTitle: L10n.Identification.ScanInstructions.title,
                       instructionsBody: L10n.Identification.ScanInstructions.body,
                       instructionsScanButtonTitle: L10n.Identification.Scan.scan,
                       scanTitle: L10n.Identification.Scan.Title.ios,
                       scanBody: L10n.Identification.Scan.Message.ios,
                       scanButton: L10n.Identification.Scan.scan)
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
