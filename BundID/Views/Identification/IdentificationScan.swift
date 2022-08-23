import SwiftUI
import ComposableArchitecture
import Combine
import Lottie

enum IdentificationScanError: Equatable {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct IdentificationScanState: Equatable, IDInteractionHandler {
    let request: EIDAuthenticationRequest
    
    var pin: String
    var pinCallback: PINCallback
    var attempt = 0
    var isScanning: Bool = false
    var isRetryAvailable: Bool = true
    var showProgressCaption: Bool = false
    var error: IdentificationScanError?
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
    case identifiedSuccessfullyWithRedirect(EIDAuthenticationRequest, redirectURL: String)
    case identifiedSuccessfullyWithoutRedirect(EIDAuthenticationRequest)
    case error(CardErrorType)
    case end
    case showNFCInfo
    case dismissNFCInfo
#if PREVIEW
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

let identificationScanReducer = Reducer<IdentificationScanState, IdentificationScanAction, AppEnvironment> { state, action, environment in
    
    switch action {
    case .onAppear:
        guard !state.isScanning else { return .none }
        return Effect(value: .startScan)
    case .startScan:
        state.pinCallback(state.pin)
        state.isScanning = true
        return .none
#if PREVIEW
    case .runDebugSequence:
        return .none
#endif
    case .idInteractionEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .idInteractionEvent(.failure(let error)):
        state.error = .idCardInteraction(error)
        state.isScanning = false
        switch error {
        case .cardDeactivated:
            return Effect(value: .error(.cardDeactivated))
        case .cardBlocked:
            return Effect(value: .error(.cardBlocked))
        default:
            return .none
        }
    case .wrongPIN:
        return .none
    case .identifiedSuccessfullyWithoutRedirect:
        state.isScanning = false
        return .none
    case .identifiedSuccessfullyWithRedirect:
        state.isScanning = false
        return .none
    case .error:
        return .none
    case .end:
        return .none
    case .showNFCInfo:
        state.nfcInfoAlert = AlertState(title: TextState(L10n.FirstTimeUser.Scan.Info.title),
                                        message: TextState(L10n.FirstTimeUser.Scan.Info.message),
                                        dismissButton: .cancel(TextState(L10n.General.ok),
                                                               action: .send(.dismissNFCInfo)))
        return .none
    case .dismissNFCInfo:
        state.nfcInfoAlert = nil
        return .none
    }
}

extension IdentificationScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<IdentificationScanAction, Never> {
        switch event {
        case .requestPIN(remainingAttempts: let remainingAttempts, pinCallback: let callback):
            
            pinCallback = PINCallback(id: environment.uuidFactory(), callback: callback)
            isScanning = false
            isRetryAvailable = true
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = remainingAttempts else {
                return .none
            }
            
            return Effect(value: .wrongPIN(remainingAttempts: remainingAttempts))
        case .requestPINAndCAN:
            return Effect(value: .error(.cardSuspended))
        case .authenticationStarted,
                .cardInteractionComplete,
                .cardRecognized:
            return .none
        case .authenticationSuccessful:
            authenticationSuccessful = true
            return .none
        case .cardRemoved:
            authenticationSuccessful = false
            return .none
        case .processCompletedSuccessfullyWithRedirect(let urlString) where authenticationSuccessful:
            return Effect(value: .identifiedSuccessfullyWithRedirect(request, redirectURL: urlString))
        case .processCompletedSuccessfullyWithoutRedirect:
            error = .unexpectedEvent(.processCompletedSuccessfullyWithoutRedirect)
            isScanning = false
            isRetryAvailable = false
            return .none
        case .processCompletedSuccessfullyWithRedirect(let urlString):
            error = .unexpectedEvent(.processCompletedSuccessfullyWithRedirect(url: urlString))
            isScanning = false
            isRetryAvailable = false
            return .none
        default:
            return .none
        }
    }
}

extension IdentificationScanState {
    var errorTitle: String? {
        switch self.error {
        case .idCardInteraction:
            return L10n.FirstTimeUser.Scan.ScanError.IdCardInteraction.title
        case .unexpectedEvent:
            return L10n.FirstTimeUser.Scan.ScanError.UnexpectedEvent.title
        default:
            return nil
        }
    }
    
    var errorBody: String? {
        switch self.error {
        case .idCardInteraction:
            return L10n.FirstTimeUser.Scan.ScanError.IdCardInteraction.body
        case .unexpectedEvent:
            return L10n.FirstTimeUser.Scan.ScanError.UnexpectedEvent.body
        default:
            return nil
        }
    }
    
    var showLottie: Bool {
        switch self.error {
        case .unexpectedEvent:
            return false
        default:
            return true
        }
    }
}

struct IdentificationScan: View {
    
    var store: Store<IdentificationScanState, IdentificationScanAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    if viewStore.state.showLottie {
                        LottieView(name: "animation_id-scan", backgroundColor: Color(0xEBEFF2))
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        Spacer()
                    }
                    
                    if viewStore.error != nil {
                        HeaderView(title: L10n.Identification.Scan.UnexpectedError.title, message: L10n.Identification.Scan.UnexpectedError.message)
                    }
                    if viewStore.isScanning {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                                .scaleEffect(3)
                                .frame(maxWidth: .infinity)
                                .padding(50)
                            if viewStore.showProgressCaption {
                                Text(L10n.FirstTimeUser.Scan.Progress.caption)
                                    .font(.bundTitle)
                                    .foregroundColor(.blackish)
                                    .padding(.bottom, 50)
                            }
                        }
                    } else {
                        ScanBody(title: L10n.Identification.Scan.title,
                                 message: L10n.Identification.Scan.message,
                                 infoTapped: { viewStore.send(.showNFCInfo) },
                                 helpTapped: { })
                        if viewStore.isRetryAvailable {
                            DialogButtons(store: store.stateless,
                                          secondary: nil,
                                          primary: .init(title: L10n.Identification.Scan.scan, action: .startScan))
                            .disabled(viewStore.isScanning)
                        }
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
