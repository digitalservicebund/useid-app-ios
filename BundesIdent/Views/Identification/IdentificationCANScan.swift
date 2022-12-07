import SwiftUI
import ComposableArchitecture
import Combine
import Sentry

struct IdentificationCANScanState: Equatable, IDInteractionHandler {
    let request: EIDAuthenticationRequest
    
    var pin: String
    var can: String
    var pinCANCallback: PINCANCallback
    var shared: SharedScanState = SharedScanState()
    
    var authenticationSuccessful = false
    var alert: AlertState<IdentificationCANScanAction>?
#if PREVIEW
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationCANScanAction? {
        return .scanEvent(event)
    }
}

enum IdentificationCANScanAction: Equatable {
    case onAppear
    case shared(SharedScanAction)
    case scanEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case wrongPIN(remainingAttempts: Int)
    case identifiedSuccessfully(redirectURL: URL)
    case requestPINAndCAN(EIDAuthenticationRequest, PINCANCallback)
    case requestCAN
    case error(ScanErrorState)
    case cancelIdentification
    case dismiss
    case dismissAlert
#if PREVIEW
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

let identificationCANScanReducer = Reducer<IdentificationCANScanState, IdentificationCANScanAction, AppEnvironment> { state, action, environment in
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
                           analytics: environment.analytics)
    case .scanEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .scanEvent(.failure(let error)):
        RedactedIDCardInteractionError(error).flatMap(environment.issueTracker.capture(error:))
        
        state.shared.isScanning = false
        switch error {
        case .cardDeactivated:
            return Effect(value: .error(ScanErrorState(errorType: .cardDeactivated, retry: false)))
        case .cardBlocked:
            return Effect(value: .error(ScanErrorState(errorType: .cardBlocked, retry: false)))
        default:
            return Effect(value: .error(ScanErrorState(errorType: .idCardInteraction(error), retry: false)))
        }
    case .wrongPIN:
        state.shared.isScanning = false
        return .none
    case .identifiedSuccessfully(let redirectURL):
        environment.storageManager.setupCompleted = true
        environment.storageManager.identifiedOnce = true
        
        return .concatenate(.trackEvent(category: "identification", action: "success", analytics: environment.analytics),
                            Effect(value: .dismiss),
                            .openURL(redirectURL, urlOpener: environment.urlOpener))
    case .shared(.showNFCInfo):
        state.alert = AlertState(title: TextState(L10n.HelpNFC.title),
                                 message: TextState(L10n.HelpNFC.body),
                                 dismissButton: .cancel(TextState(L10n.General.ok),
                                                        action: .send(.dismissAlert)))
        
        return .trackEvent(category: "identification",
                           action: "alertShown",
                           name: "NFCInfo",
                           analytics: environment.analytics)
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

extension IdentificationCANScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<IdentificationCANScanAction, Never> {
        switch event {
        case .requestPINAndCAN(let callback):
            environment.logger.info("Request PIN and CAN")
            pinCANCallback = PINCANCallback(id: environment.uuidFactory(), callback: callback)
            shared.isScanning = false
            shared.scanAvailable = true
            if !shared.cardRecognized {
                return .none
            }
            return Effect(value: .requestPINAndCAN(request, pinCANCallback))
        case .authenticationStarted:
            environment.logger.info("Authentication started.")
            shared.isScanning = true
        case .cardInteractionComplete:
            environment.logger.info("Card interaction complete.")
        case .requestCardInsertion:
            environment.logger.info("Request Card insertion.")
            shared.isScanning = true
            shared.cardRecognized = false
        case .cardRecognized:
            environment.logger.info("Card recognized.")
            shared.isScanning = true
            shared.cardRecognized = true
        case .authenticationSuccessful:
            environment.logger.info("Authentication succesful.")
            shared.isScanning = true
            authenticationSuccessful = true
        case .cardRemoved:
            environment.logger.info("Card removed.")
            authenticationSuccessful = false
        case .processCompletedSuccessfullyWithRedirect(let redirect):
            environment.logger.info("Process Completed Successfully With Redirect")
            return Effect(value: .identifiedSuccessfully(redirectURL: redirect))
        case .processCompletedSuccessfullyWithoutRedirect:
            shared.scanAvailable = false
            environment.issueTracker.capture(error: RedactedEIDInteractionEventError(.processCompletedSuccessfullyWithoutRedirect))
            environment.logger.error("Received unexpected event.")
            return Effect(value: .error(ScanErrorState(errorType: .unexpectedEvent(event), retry: shared.scanAvailable)))
        default:
            environment.issueTracker.capture(error: RedactedEIDInteractionEventError(event))
            environment.logger.error("Received unexpected event.")
            return Effect(value: .error(ScanErrorState(errorType: .unexpectedEvent(event), retry: true)))
        }
        return .none
    }
}

struct IdentificationCANScan: View {
    
    var store: Store<IdentificationCANScanState, IdentificationCANScanAction>
    
    var body: some View {
        SharedScan(store: store.scope(state: \.shared, action: IdentificationCANScanAction.shared),
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
        .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: IdentificationCANScanAction.runDebugSequence)
#endif
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

struct IdentificationCANScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationCANScan(store: Store(initialState: IdentificationCANScanState(request: .preview,
                                                                                    pin: "123456",
                                                                                    can: "123456",
                                                                                    pinCANCallback: PINCANCallback(id: .zero, callback: { _, _ in })),
                                           reducer: .empty,
                                           environment: AppEnvironment.preview))
        
        IdentificationCANScan(store: Store(initialState: IdentificationCANScanState(request: .preview,
                                                                                    pin: "123456",
                                                                                    can: "123456",
                                                                                    pinCANCallback: PINCANCallback(id: .zero, callback: { _, _ in }), shared: SharedScanState(isScanning: true)),
                                           reducer: .empty,
                                           environment: AppEnvironment.preview))
    }
}
