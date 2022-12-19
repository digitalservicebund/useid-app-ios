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
    
    struct State: Equatable, IDInteractionHandler {
        let request: EIDAuthenticationRequest
        
        var pin: String
        var pinCallback: PINCallback
        var shared: SharedScan.State = .init()
        
        var authenticationSuccessful = false
        var alert: AlertState<Action>?
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
        case identifiedSuccessfully(request: EIDAuthenticationRequest, redirectURL: URL)
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
            return Effect(value: .shared(.startScan))
        case .shared(.startScan):
            state.shared.showInstructions = false
            state.shared.cardRecognized = false
            guard !state.shared.isScanning else { return .none }
            state.pinCallback(state.pin)
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
                return Effect(value: .error(ScanError.State(errorType: .cardDeactivated, retry: false)))
            case .cardBlocked:
                return Effect(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
            default:
                return Effect(value: .error(ScanError.State(errorType: .idCardInteraction(error), retry: false)))
            }
        case .wrongPIN:
            state.shared.isScanning = false
            return .none
        case .identifiedSuccessfully:
            storageManager.setupCompleted = true
            storageManager.identifiedOnce = true
            return .trackEvent(category: "identification", action: "success", analytics: analytics)
            
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
            state.alert = AlertState(title: TextState(verbatim: L10n.Identification.ConfirmEnd.title),
                                     message: TextState(verbatim: L10n.Identification.ConfirmEnd.message),
                                     primaryButton: .destructive(TextState(verbatim: L10n.Identification.ConfirmEnd.confirm),
                                                                 action: .send(.dismiss)),
                                     secondaryButton: .cancel(TextState(verbatim: L10n.Identification.ConfirmEnd.deny)))
            return .none
        case .dismissAlert:
            state.alert = nil
            return .none
        default:
            return .none
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> Effect<IdentificationPINScan.Action, Never> {
        switch event {
        case .requestPIN(remainingAttempts: let remainingAttempts, pinCallback: let callback):
            let callbackId = uuid.callAsFunction()
            state.pinCallback = PINCallback(id: callbackId, callback: callback)
            state.shared.isScanning = false
            state.shared.scanAvailable = true
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts else {
                logger.info("Identification cancelled")
                if state.shared.cardRecognized {
                    issueTracker.capture(error: IdentificationScanError.cancelAfterCardRecognized)
                }
                return .none
            }
            logger.info("PIN request: \(callbackId)")
            return Effect(value: .wrongPIN(remainingAttempts: remainingAttempts))
        case .requestPINAndCAN(let callback):
            let callbackId = uuid.callAsFunction()
            let pinCANCallback = PINCANCallback(id: callbackId, callback: callback)
            logger.info("PIN and CAN request: \(callbackId)")
            state.shared.isScanning = false
            state.shared.scanAvailable = true
            return Effect(value: .requestPINAndCAN(state.request, pinCANCallback))
                .delay(for: 2, scheduler: mainQueue) // this delay is here to fix a bug where this particular screen was presented incorrectly
                .eraseToEffect()
        case .authenticationStarted:
            logger.info("Authentication started.")
            state.shared.isScanning = true
        case .cardInteractionComplete:
            logger.info("Card interaction complete.")
        case .requestCardInsertion:
            state.shared.isScanning = true
        case .cardRecognized:
            logger.info("Card recognized.")
            state.shared.cardRecognized = true
            state.shared.isScanning = true
        case .authenticationSuccessful:
            logger.info("Authentication succesful.")
            state.shared.isScanning = true
            state.authenticationSuccessful = true
        case .cardRemoved:
            logger.info("Card removed.")
            state.authenticationSuccessful = false
        case .processCompletedSuccessfullyWithRedirect(let redirectURL):
            logger.info("Authentication successfully with redirect.")
            return Effect(value: .identifiedSuccessfully(request: state.request, redirectURL: redirectURL))
        case .processCompletedSuccessfullyWithoutRedirect:
            state.shared.scanAvailable = false
            issueTracker.capture(error: RedactedEIDInteractionEventError(.processCompletedSuccessfullyWithoutRedirect))
            logger.error("Received unexpected event.")
            return Effect(value: .error(ScanError.State(errorType: .unexpectedEvent(.processCompletedSuccessfullyWithoutRedirect), retry: state.shared.scanAvailable)))
        default:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return Effect(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct IdentificationPINScanView: View {
    
    var store: Store<IdentificationPINScan.State, IdentificationPINScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: IdentificationPINScan.Action.shared),
                       instructionsTitle: L10n.Identification.ScanInstructions.title,
                       instructionsBody: L10n.Identification.ScanInstructions.body,
                       instructionsScanButtonTitle: L10n.Identification.Scan.scan,
                       scanTitle: L10n.Identification.Scan.title,
                       scanBody: L10n.Identification.Scan.message,
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

struct IdentificationScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationPINScanView(store: Store(initialState: IdentificationPINScan.State(request: .preview,
                                                                                         pin: "123456",
                                                                                         pinCallback: PINCallback(id: .zero, callback: { _ in })),
                                               reducer: IdentificationPINScan()))
        IdentificationPINScanView(store: Store(initialState: IdentificationPINScan.State(request: .preview,
                                                                                         pin: "123456",
                                                                                         pinCallback: PINCallback(id: .zero, callback: { _ in }), shared: SharedScan.State(isScanning: true)),
                                               reducer: IdentificationPINScan()))
    }
}
