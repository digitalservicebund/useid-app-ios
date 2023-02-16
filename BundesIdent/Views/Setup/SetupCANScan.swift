import SwiftUI
import ComposableArchitecture
import Combine
import Sentry

struct SetupCANScan: ReducerProtocol {
    
    @Dependency(\.analytics) var analytics
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.storageManager) var storageManager
    @Dependency(\.logger) var logger
    @Dependency(\.uuid) var uuid
    
    struct State: Equatable, IDInteractionHandler {
        var transportPIN: String
        var newPIN: String
        var can: String
        var canAndChangedPINCallback: CANAndChangedPINCallback
        var shared: SharedScan.State = .init()
        
        var authenticationSuccessful = false
        var alert: AlertState<SetupCANScan.Action>?
#if PREVIEW
        var availableDebugActions: [ChangePINDebugSequence] = []
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
        case incorrectCAN(callback: CANAndChangedPINCallback)
        case scannedSuccessfully
        case error(ScanError.State)
        case cancelSetup
        case dismiss
        case dismissAlert
#if PREVIEW
        case runDebugSequence(ChangePINDebugSequence)
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
            let payload = CANAndChangedPINCallbackPayload(can: state.can, oldPIN: state.transportPIN, newPIN: state.newPIN)
            state.canAndChangedPINCallback(payload)
            state.shared.isScanning = true
            return .trackEvent(category: "Setup",
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
        case .scannedSuccessfully:
            storageManager.setupCompleted = true
            return .cancel(id: CancelId.self)
        case .shared(.showNFCInfo):
            state.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                     message: TextState(L10n.HelpNFC.body),
                                     dismissButton: .cancel(TextState(L10n.General.ok),
                                                            action: .send(.dismissAlert)))
            
            return .trackEvent(category: "Setup",
                               action: "alertShown",
                               name: "NFCInfo",
                               analytics: analytics)
        case .cancelSetup:
            state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.title),
                                     message: TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.message),
                                     primaryButton: .destructive(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.confirm),
                                                                 action: .send(.dismiss)),
                                     secondaryButton: .cancel(TextState(verbatim: L10n.FirstTimeUser.ConfirmEnd.deny)))
            return .none
        case .dismissAlert:
            state.alert = nil
            return .none
        default:
            return .none
        }
    }
    
    func handle(state: inout State, event: EIDInteractionEvent) -> Effect<SetupCANScan.Action, Never> {
        switch event {
        case .authenticationStarted:
            logger.info("Authentication started.")
            state.shared.isScanning = true
        case .cardInteractionComplete:
            logger.info("Card interaction complete.")
        case .requestCardInsertion:
            logger.info("Request Card insertion.")
            state.shared.showProgressCaption = nil
            state.shared.isScanning = true
            state.shared.cardRecognized = false
        case .cardRecognized:
            logger.info("Card recognized.")
            state.shared.isScanning = true
            state.shared.cardRecognized = true
        case .cardRemoved:
            state.shared.showProgressCaption = ProgressCaption(title: L10n.FirstTimeUser.Scan.Progress.title,
                                                               body: L10n.FirstTimeUser.Scan.Progress.body)
            logger.info("Card removed.")
            state.authenticationSuccessful = false
        case .processCompletedSuccessfullyWithoutRedirect:
            return Effect(value: .scannedSuccessfully)
        case .requestCANAndChangedPIN(pinCallback: let pinCallback):
            logger.info("Wrong CAN provided")
            state.shared.isScanning = false
            let identifiedCallback = CANAndChangedPINCallback(id: uuid()) { payload in
                pinCallback(payload.oldPIN, payload.can, payload.newPIN)
            }
            return Effect(value: .incorrectCAN(callback: identifiedCallback))
        case .requestPUK:
            logger.info("PUK requested, so card is blocked. Callback not implemented yet.")
            return Effect(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
        case .requestPIN,
             .requestCAN,
             .requestPINAndCAN,
             .processCompletedSuccessfullyWithRedirect,
             .requestAuthenticationRequestConfirmation,
             .authenticationSuccessful,
             .requestChangedPIN,
             .pinManagementStarted:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return Effect(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct SetupCANScanView: View {
    
    var store: Store<SetupCANScan.State, SetupCANScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: SetupCANScan.Action.shared),
                       instructionsTitle: L10n.FirstTimeUser.ScanInstructions.title,
                       instructionsBody: L10n.FirstTimeUser.ScanInstructions.body,
                       instructionsScanButtonTitle: L10n.FirstTimeUser.Scan.scan,
                       scanTitle: L10n.FirstTimeUser.Scan.Title.ios,
                       scanBody: L10n.FirstTimeUser.Scan.body,
                       scanButton: L10n.FirstTimeUser.Scan.scan)
            .onAppear {
                ViewStore(store).send(.onAppear)
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.General.cancel) {
                        ViewStore(store).send(.cancelSetup)
                    }
                    .bodyLRegular(color: .accentColor)
                }
            }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: SetupCANScan.Action.runDebugSequence)
#endif
            .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

#if DEBUG

struct SetupCANScan_Previews: PreviewProvider {
    static var previews: some View {
        SetupCANScanView(store: Store(initialState: SetupCANScan.State(transportPIN: "12345",
                                                                       newPIN: "123456",
                                                                       can: "123456",
                                                                       canAndChangedPINCallback: CANAndChangedPINCallback(id: .zero, callback: { _ in })),
                                      reducer: SetupCANScan()))
        
        SetupCANScanView(store: Store(initialState: SetupCANScan.State(transportPIN: "12345",
                                                                       newPIN: "123456",
                                                                       can: "123456",
                                                                       canAndChangedPINCallback: CANAndChangedPINCallback(id: .zero, callback: { _ in }), shared: SharedScan.State(isScanning: true)),
                                      reducer: SetupCANScan()))
    }
}

#endif
