import SwiftUI
import ComposableArchitecture
import Combine
import Lottie

enum IdentificationScanError: Equatable {
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct IdentificationScanState: Equatable, IDInteractionHandler {
    var isScanning: Bool = true
    var showProgressCaption: Bool = false
    var tokenURL: String
    var pin: String
    var pinCallback: PINCallback
    var requestedPIN = false
    var error: IdentificationScanError?
    var remainingAttempts: Int?
    var attempt = 0
    var authenticationSuccessful = false
#if DEBUG
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
    case identifiedSuccessfully
    case cardDeactivated
    case cardBlocked
    case cardSuspended
#if DEBUG
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

let identificationScanReducer = Reducer<IdentificationScanState, IdentificationScanAction, AppEnvironment> { state, action, environment in
    
    switch action {
    case .onAppear:
        return Effect(value: .startScan)
    case .startScan:
        guard let pinCallback = state.pinCallback,
              let pin = state.pin else { return .none }
        pinCallback(pin)
        state.isScanning = true
        return .none
    case .runDebugSequence:
        return .none
    case .idInteractionEvent(.success(let event)):
        return state.handle(event: event, environment: environment)
    case .idInteractionEvent(.failure(let error)):
        state.error = .idCardInteraction(error)
        state.isScanning = false
        switch error {
        case .cardDeactivated:
            return Effect(value: .cardDeactivated)
        case .cardBlocked:
            return Effect(value: .cardBlocked)
        default:
            return .none
        }
    case .wrongPIN(let remainingAttempts):
        state.remainingAttempts = remainingAttempts
        return .none
    case .identifiedSuccessfully:
        state.isScanning = false
        return .none
    case .cardBlocked:
        return .none
    case .cardSuspended:
        return .none
    case .cardDeactivated:
        return .none
    }
}

extension IdentificationScanState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<IdentificationScanAction, Never> {
        switch event {
        case .requestPIN(remainingAttempts: let remainingAttempts, pinCallback: let callback):
            
            pinCallback = PINCallback(id: environment.uuidFactory(), callback: callback)
            
            // This is our signal that the user canceled (for now)
            guard let remainingAttempts = remainingAttempts else {
                isScanning = false
                return .none
            }
            
            return Effect(value: .wrongPIN(remainingAttempts: remainingAttempts))
        case .requestPINAndCAN:
            return Effect(value: .cardSuspended)
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
        case .processCompletedSuccessfully where authenticationSuccessful:
            return Effect(value: .identifiedSuccessfully)
        case .processCompletedSuccessfully:
            error = .unexpectedEvent(.processCompletedSuccessfully)
            isScanning = false
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
                        LottieView(name: "38076-id-scan")
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                        Spacer()
                    }
                    
                    if let title = viewStore.state.errorTitle {
                        HeaderView(title: title, message: viewStore.state.errorBody)
                    }
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
                    DialogButtons(store: store.stateless,
                                  secondary: nil,
                                  primary: .init(title: L10n.FirstTimeUser.Scan.scan, action: .startScan))
                    .disabled(viewStore.isScanning)
                }
            }.onChange(of: viewStore.state.attempt, perform: { _ in
                viewStore.send(.startScan)
            })
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
        .toolbar {
#if DEBUG
            ToolbarItem(placement: .primaryAction) {
                WithViewStore(store) { viewStore in
                    Menu {
                        ForEach(viewStore.availableDebugActions) { sequence in
                            Button(sequence.id) {
                                viewStore.send(.runDebugSequence(sequence))
                            }
                        }
                    } label: {
                        Image(systemName: "wrench")
                    }
                }
            }
#endif
        }
    }
}

struct IdentificationScan_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationScan(store: Store(initialState: IdentificationScanState(tokenURL: demoTokenURL, pin: "123456", pinCallback: PINCallback(id: .zero, callback: { _ in })), reducer: .empty, environment: AppEnvironment.preview))
        IdentificationScan(store: Store(initialState: IdentificationScanState(isScanning: true, tokenURL: demoTokenURL, pin: "123456", pinCallback: PINCallback(id: .zero, callback: { _ in })), reducer: .empty, environment: AppEnvironment.preview))
    }
}
