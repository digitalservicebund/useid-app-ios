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
    struct State: Equatable, IDInteractionHandler {
        let request: EIDAuthenticationRequest
        
        var pin: String
        var can: String
        var pinCANCallback: PINCANCallback
        var shared: SharedScan.State = .init()
        
        var authenticationSuccessful = false
        var alert: AlertState<IdentificationCANScan.Action>?
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationCANScan.Action? {
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
        case requestCAN
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
            guard !state.shared.isScanning else { return .none }
            state.pinCANCallback((state.pin, state.can))
            state.shared.isScanning = true
            return .trackEvent(category: "identification",
                               action: "buttonPressed",
                               name: "canScan",
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
    
    func handle(state: inout State, event: EIDInteractionEvent) -> Effect<IdentificationCANScan.Action, Never> {
        switch event {
        case .requestPINAndCAN(let callback):
            logger.info("Request PIN and CAN")
            state.pinCANCallback = PINCANCallback(id: uuid.callAsFunction(), callback: callback)
            state.shared.isScanning = false
            state.shared.scanAvailable = true
            if !state.shared.cardRecognized {
                return .none
            }
            return Effect(value: .requestPINAndCAN(state.request, state.pinCANCallback))
        case .authenticationStarted:
            logger.info("Authentication started.")
            state.shared.isScanning = true
        case .cardInteractionComplete:
            logger.info("Card interaction complete.")
        case .requestCardInsertion:
            logger.info("Request Card insertion.")
            state.shared.isScanning = true
            state.shared.cardRecognized = false
        case .cardRecognized:
            logger.info("Card recognized.")
            state.shared.isScanning = true
            state.shared.cardRecognized = true
        case .authenticationSuccessful:
            logger.info("Authentication succesful.")
            state.shared.isScanning = true
            state.authenticationSuccessful = true
        case .cardRemoved:
            logger.info("Card removed.")
            state.authenticationSuccessful = false
        case .processCompletedSuccessfullyWithRedirect(let redirectURL):
            logger.info("Process Completed Successfully With Redirect")
            return Effect(value: .identifiedSuccessfully(request: state.request, redirectURL: redirectURL))
        case .processCompletedSuccessfullyWithoutRedirect:
            state.shared.scanAvailable = false
            issueTracker.capture(error: RedactedEIDInteractionEventError(.processCompletedSuccessfullyWithoutRedirect))
            logger.error("Received unexpected event.")
            return Effect(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: state.shared.scanAvailable)))
        default:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return Effect(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct IdentificationCANScanView: View {
    
    var store: Store<IdentificationCANScan.State, IdentificationCANScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: IdentificationCANScan.Action.shared),
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
                    .bodyLRegular(color: .accentColor)
                }
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: IdentificationCANScan.Action.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

struct IdentificationCANScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationCANScanView(store: Store(initialState: IdentificationCANScan.State(request: .preview,
                                                                                         pin: "123456",
                                                                                         can: "123456",
                                                                                         pinCANCallback: PINCANCallback(id: .zero, callback: { _, _ in })),
                                               reducer: IdentificationCANScan()))
        
        IdentificationCANScanView(store: Store(initialState: IdentificationCANScan.State(request: .preview,
                                                                                         pin: "123456",
                                                                                         can: "123456",
                                                                                         pinCANCallback: PINCANCallback(id: .zero, callback: { _, _ in }), shared: SharedScan.State(isScanning: true)),
                                               reducer: IdentificationCANScan()))
    }
}
