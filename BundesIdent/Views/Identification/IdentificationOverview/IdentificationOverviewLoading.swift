import ComposableArchitecture
import SwiftUI
import Sentry

struct IdentificationOverviewLoading: ReducerProtocol {
    @Dependency(\.uuid) var uuid
    @Dependency(\.issueTracker) var issueTracker
    
    struct State: Equatable {
        var onAppearCalled: Bool
        var canGoBackToSetupIntro: Bool
        
        init(onAppearCalled: Bool = false, canGoBackToSetupIntro: Bool = false) {
            self.onAppearCalled = onAppearCalled
            self.canGoBackToSetupIntro = canGoBackToSetupIntro
        }
        
#if PREVIEW
        var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    }
    
    enum Action: Equatable {
        case onAppear
        case identify
        case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
        case done(EIDAuthenticationRequest, IdentifiableCallback<FlaggedAttributes>)
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
        case .idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(let request, let handler))):
            return EffectTask(value: .done(request, IdentifiableCallback(id: uuid.callAsFunction(), callback: handler)))
        case .idInteractionEvent(.failure(let error)):
            RedactedIDCardInteractionError(error).flatMap(issueTracker.capture(error:))
            return EffectTask(value: .failure(IdentifiableError(error)))
        case .idInteractionEvent:
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
