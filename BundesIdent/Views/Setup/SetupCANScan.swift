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
    @Dependency(\.idInteractionManager) var idInteractionManager
    
    struct State: Equatable, IDInteractionHandler {
        var transportPIN: String
        var newPIN: String
        var can: String
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
        case incorrectCAN
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
            return EffectTask(value: .shared(.startScan))
        case .shared(.startScan):
            guard !state.shared.isScanning else { return .none }
            state.shared.isScanning = true
            idInteractionManager.setCAN(state.can)
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
                state.shared.scanAvailable = false
                return EffectTask(value: .error(ScanError.State(errorType: .cardDeactivated, retry: state.shared.scanAvailable)))
            case .cardBlocked:
                state.shared.scanAvailable = false
                return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: state.shared.scanAvailable)))
            default:
                state.shared.scanAvailable = true
                return EffectTask(value: .error(ScanError.State(errorType: .idCardInteraction(error), retry: state.shared.scanAvailable)))
            }
        case .wrongPIN:
            state.shared.isScanning = false
            return .none
        case .scannedSuccessfully:
            storageManager.setupCompleted = true
            return .none
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
    
    func handle(state: inout State, event: EIDInteractionEvent) -> EffectTask<SetupCANScan.Action> {
        switch event {
        case .authenticationStarted:
            logger.info("Authentication started.")
            state.shared.isScanning = true
        case .pinChangeStarted:
            logger.info("PIN Change started.")
        case .cardInsertionRequested:
            logger.info("Card insertion requested.")
            state.shared.isScanning = true
            state.shared.cardRecognized = false
        case .cardRecognized:
            logger.info("Card recognized.")
            state.shared.isScanning = true
            state.shared.cardRecognized = true
        case .cardRemoved:
            logger.info("Card removed.")
            state.authenticationSuccessful = false
        case .pinChangeSucceeded:
            return EffectTask(value: .scannedSuccessfully)
        case .canRequested:
            // TODO: Should’t go into incorrect CAN when resume after cancellation
            logger.info("Wrong CAN provided")
            state.shared.isScanning = false
            return EffectTask(value: .incorrectCAN)
        case .pinRequested:
            idInteractionManager.setPIN(state.transportPIN)
            return .none
        case .pinRequested:
            // TODO: callback
//            let identifiedCallback = CANAndChangedPINCallback(id: uuid()) { payload in
//                pinCallback(payload.oldPIN, payload.can, payload.newPIN)
//            }
//            if state.canAndChangedPINCallback == nil {
//                logger.info("CAN and changed PIN requested after cancelling scan. Directly providing previous values to continue the flow.")
//                identifiedCallback(CANAndChangedPINCallbackPayload(can: state.can,
//                                                                   oldPIN: state.transportPIN,
//                                                                   newPIN: state.newPIN))
//                state.shared.isScanning = true
//                return .none
//            } else {
//                logger.info("Wrong CAN provided")
//                state.canAndChangedPINCallback = identifiedCallback
//                state.shared.isScanning = false
//                return EffectTask(value: .incorrectCAN(callback: identifiedCallback))
//            }
            return .none
        case .pukRequested:
            logger.info("PUK requested, so card is blocked. Callback not implemented yet.")
            return EffectTask(value: .error(ScanError.State(errorType: .cardBlocked, retry: false)))
            
        case .newPINRequested:
            idInteractionManager.setNewPIN(state.newPIN)
            return .none
        case .authenticationSucceeded,
             .authenticationRequestConfirmationRequested,
             .certificateDescriptionRetrieved:
            issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            logger.error("Received unexpected event.")
            return EffectTask(value: .error(ScanError.State(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct SetupCANScanView: View {
    
    var store: Store<SetupCANScan.State, SetupCANScan.Action>
    
    var body: some View {
        SharedScanView(store: store.scope(state: \.shared, action: SetupCANScan.Action.shared))
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
                                                                       can: "123456"),
                                      reducer: SetupCANScan()))
        
        SetupCANScanView(store: Store(initialState: SetupCANScan.State(transportPIN: "12345",
                                                                       newPIN: "123456",
                                                                       can: "123456",
                                                                       shared: SharedScan.State(isScanning: true)),
                                      reducer: SetupCANScan()))
    }
}

#endif
