import ComposableArchitecture
import SwiftUI
import Sentry

struct IdentificationOverviewLoading: ReducerProtocol {
    @Dependency(\.uuid) var uuid
    @Dependency(\.issueTracker) var issueTracker
    @Dependency(\.logger) var logger
    @Dependency(\.eIDInteractionManager) var eIDInteractionManager
    
    struct State: Equatable {
        var onAppearCalled: Bool
        var canGoBackToSetupIntro: Bool
        var authenticationRequest: AuthenticationRequest?
        
        init(onAppearCalled: Bool = false, canGoBackToSetupIntro: Bool = false, authenticationRequest: AuthenticationRequest? = nil) {
            self.onAppearCalled = onAppearCalled
            self.canGoBackToSetupIntro = canGoBackToSetupIntro
            self.authenticationRequest = authenticationRequest
        }
        
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    }
    
    enum Action: Equatable {
        case onAppear
        case identify
        case eIDInteractionEvent(Result<EIDInteractionEvent, EIDInteractionError>)
        case done(AuthenticationRequest, CertificateDescription)
        case failure(IdentifiableError)
#if PREVIEW
        case runDebugSequence(IdentifyDebugSequence)
#endif
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            guard !state.onAppearCalled else {
                return .none
            }
            state.onAppearCalled = true
            
            return EffectTask(value: .identify)
        case .identify:
            return .none
        case .eIDInteractionEvent(.success(.authenticationRequestConfirmationRequested(let request))):
            state.authenticationRequest = request
            eIDInteractionManager.retrieveCertificateDescription()
            return .none
        case .eIDInteractionEvent(.success(.certificateDescriptionRetrieved(let certificateDescription))):
            guard let authenticationRequest = state.authenticationRequest else {
                logger.error("Missing authenticationRequest, this must not happen.")
                return .none // EffectTask(value: .failure(<#T##IdentifiableError#>))
            }
            return EffectTask(value: .done(authenticationRequest, certificateDescription))
        case .eIDInteractionEvent(.failure(let error)):
            RedactedEIDInteractionError(error).flatMap(issueTracker.capture(error:))
            return EffectTask(value: .failure(IdentifiableError(error)))
        case .eIDInteractionEvent:
            return .none
        case .done:
            return .none
        case .failure:
            return .none
#if PREVIEW
        case .runDebugSequence:
            return .none
#endif
        }
    }
}
struct IdentificationOverviewLoadingView: View {
    var store: Store<IdentificationOverviewLoading.State, IdentificationOverviewLoading.Action>
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                .scaleEffect(3)
                .frame(maxWidth: .infinity)
                .padding(50)
            VStack(spacing: 24) {
                Text(L10n.Identification.FetchMetadata.pleaseWait)
                    .bodyLRegular()
            }
            .padding(.bottom, 50)
        }
        .onAppear {
            ViewStore(store.stateless).send(.onAppear)
        }
#if PREVIEW
            .identifyDebugMenu(store: store.scope(state: \.availableDebugActions), action: IdentificationOverviewLoading.Action.runDebugSequence)
#endif
    }
}
