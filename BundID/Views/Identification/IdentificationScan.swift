import SwiftUI
import ComposableArchitecture
import Combine
import Lottie
import Sentry

enum IdentificationScanError: Error, Equatable {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct IdentificationScanState: Equatable, IDInteractionHandler {
    let request: EIDAuthenticationRequest
    
    var pin: String
    var pinCallback: PINCallback
    var attempt = 0
    var isScanning: Bool = false
    var scanAvailable: Bool = true
    var authenticationSuccessful = false
    var nfcInfoAlert: AlertState<IdentificationScanAction>?
#if PREVIEW
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationScanAction? {
        return .idInteractionEvent(event)
    }
}

enum IdentificationScanAction: Equatable {
    case onAppear
    case startScan
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case wrongPIN(remainingAttempts: Int)
    case identifiedSuccessfully(redirectURL: String)
    case error(ScanErrorState)
    case end
    case showNFCInfo
    case dismissNFCInfo
    case showHelp
#if PREVIEW
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

let identificationScanReducer = Reducer<IdentificationScanState, IdentificationScanAction, AppEnvironment> { state, action, environment in
    switch action {
    case .startScan:
        guard !state.isScanning else { return .none }
        state.pinCallback(state.pin)
        state.isScanning = true
        
        return .trackEvent(category: "identification",
                           action: "buttonPressed",
                           name: "scan",
                           analytics: environment.analytics)
    case .idInteractionEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .idInteractionEvent(.failure(let error)):
        RedactedIDCardInteractionError(error).flatMap(environment.issueTracker.capture(error:))
        
        state.isScanning = false
        switch error {
        case .cardDeactivated:
            return Effect(value: .error(ScanErrorState(errorType: .cardDeactivated, retry: false)))
        case .cardBlocked:
            return Effect(value: .error(ScanErrorState(errorType: .cardBlocked, retry: false)))
        default:
            return Effect(value: .error(ScanErrorState(errorType: .idCardInteraction(error), retry: false)))
        }
    case .wrongPIN:
        state.isScanning = false
        return .none
    case .identifiedSuccessfully(let redirectURL):
        environment.storageManager.updateSetupCompleted(true)
        
        let endEffect = Effect<IdentificationScanAction, Never>(value: .end)
        let trackingEffect = Effect<IdentificationScanAction, Never>.trackEvent(category: "identification",
                                                                                action: "success",
                                                                                analytics: environment.analytics)
        
        if let url = URL(string: redirectURL) {
            return .concatenate(.openURL(url, urlOpener: environment.urlOpener), trackingEffect, endEffect)
        } else {
            return .concatenate(trackingEffect, endEffect)
        }
    case .showNFCInfo:
        state.nfcInfoAlert = AlertState(title: TextState(L10n.HelpNFC.title),
                                        message: TextState(L10n.HelpNFC.body),
                                        dismissButton: .cancel(TextState(L10n.General.ok),
                                                               action: .send(.dismissNFCInfo)))
        
        return .trackEvent(category: "identification",
                           action: "alertShown",
                           name: "NFCInfo",
                           analytics: environment.analytics)
    case .dismissNFCInfo:
        state.nfcInfoAlert = nil
        return .none
    default:
        return .none
    }
}

extension IdentificationScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<IdentificationScanAction, Never> {
        switch event {
        case .requestPIN(remainingAttempts: let remainingAttempts, pinCallback: let callback):
            pinCallback = PINCallback(id: environment.uuidFactory(), callback: callback)
            isScanning = false
            scanAvailable = true
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = remainingAttempts else {
                return .none
            }
            
            return Effect(value: .wrongPIN(remainingAttempts: remainingAttempts))
        case .requestPINAndCAN:
            isScanning = false
            scanAvailable = false
            return Effect(value: .error(ScanErrorState(errorType: .cardSuspended, retry: scanAvailable)))
        case .requestCardInsertion,
                .authenticationStarted,
                .cardInteractionComplete,
                .cardRecognized:
            isScanning = true
            return .none
        case .authenticationSuccessful:
            isScanning = true
            authenticationSuccessful = true
            return .none
        case .cardRemoved:
            authenticationSuccessful = false
            return .none
        case .processCompletedSuccessfullyWithRedirect(let redirect):
            return Effect(value: .identifiedSuccessfully(redirectURL: redirect))
        case .processCompletedSuccessfullyWithoutRedirect:
            scanAvailable = false
            return Effect(value: .error(ScanErrorState(errorType: .unexpectedEvent(event), retry: scanAvailable)))
        default:
            return .none
        }
    }
}

struct IdentificationScan: View {
    
    var store: Store<IdentificationScanState, IdentificationScanAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    LottieView(name: Asset.animationIdScan.name,
                               backgroundColor: Color(0xEBEFF2),
                               accessiblityLabel: L10n.Scan.animationAccessibilityLabel)
                    .aspectRatio(540.0 / 367.0, contentMode: .fit)
                    
                    if viewStore.isScanning {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                                .scaleEffect(3)
                                .frame(maxWidth: .infinity)
                                .padding(50)
                        }
                    } else {
                        ScanBody(title: L10n.Identification.Scan.title,
                                 message: L10n.Identification.Scan.message,
                                 buttonTitle: L10n.Identification.Scan.scan,
                                 buttonTapped: { viewStore.send(.startScan) },
                                 nfcInfoTapped: { viewStore.send(.showNFCInfo) },
                                 helpTapped: { viewStore.send(.showHelp) })
                        .disabled(!viewStore.scanAvailable)
                    }
                }
            }.onChange(of: viewStore.state.attempt, perform: { _ in
                viewStore.send(.startScan)
            })
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .navigationBarBackButtonHidden(true)
#if PREVIEW
        .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: IdentificationScanAction.runDebugSequence)
#endif
        .alert(store.scope(state: \.nfcInfoAlert), dismiss: .dismissNFCInfo)
    }
}

struct IdentificationScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationScan(store: Store(initialState: IdentificationScanState(request: .preview, pin: "123456", pinCallback: PINCallback(id: .zero, callback: { _ in })), reducer: .empty, environment: AppEnvironment.preview))
        IdentificationScan(store: Store(initialState: IdentificationScanState(request: .preview, pin: "123456", pinCallback: PINCallback(id: .zero, callback: { _ in }), isScanning: true), reducer: .empty, environment: AppEnvironment.preview))
    }
}
