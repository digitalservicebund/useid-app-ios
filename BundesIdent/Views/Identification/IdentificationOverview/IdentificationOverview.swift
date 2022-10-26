import SwiftUI
import ComposableArchitecture
import TCACoordinators

enum IdentificationOverviewState: Equatable, IDInteractionHandler {
    case loading(IdentificationOverviewLoadingState)
    case loaded(IdentificationOverviewLoadedState)
    case error(IdentificationOverviewErrorState)
    
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationOverviewAction? {
        switch self {
        case .loading:
            return .loading(.idInteractionEvent(event))
        case .loaded:
            return .loaded(.idInteractionEvent(event))
        case .error:
            return nil
        }
    }
    
    var canGoBackToSetupIntro: Bool {
        switch self {
        case .loading(let subState):
            return subState.canGoBackToSetupIntro
        case .loaded(let subState):
            return subState.canGoBackToSetupIntro
        case .error(let subState):
            return subState.canGoBackToSetupIntro
        }
    }
    
#if PREVIEW
    var availableDebugActions: [IdentifyDebugSequence] {
        get {
            guard case .loading(let loadingState) = self else { return [] }
            return loadingState.availableDebugActions
        }
        set {
            guard case .loading(var loadingState) = self else { return }
            loadingState.availableDebugActions = newValue
            self = .loading(loadingState)
        }
    }
#endif
}

typealias PINCallback = IdentifiableCallback<String>

enum IdentificationOverviewAction: Equatable {
    case loading(IdentificationOverviewLoadingAction)
    case loaded(IdentificationOverviewLoadedAction)
    case error(IdentificationOverviewErrorAction)
    
    case onAppear
    case end
    case back
}

let identificationOverviewReducer = Reducer<IdentificationOverviewState, IdentificationOverviewAction, AppEnvironment>.combine(
    identificationOverviewLoadingReducer.pullback(state: /IdentificationOverviewState.loading,
                                                  action: /IdentificationOverviewAction.loading,
                                                  environment: { $0 }),
    identificationOverviewLoadedReducer.pullback(state: /IdentificationOverviewState.loaded,
                                                 action: /IdentificationOverviewAction.loaded,
                                                 environment: { $0 }),
    Reducer { state, action, environment in
        switch action {
        case .error(.retry):
            state = .loading(IdentificationOverviewLoadingState(canGoBackToSetupIntro: state.canGoBackToSetupIntro))
            return .none
        case .loading(.failure(let error)):
            state = .error(IdentificationOverviewErrorState(error: error, canGoBackToSetupIntro: state.canGoBackToSetupIntro))
            return .trackEvent(category: "identification",
                               action: "loadingFailed",
                               name: "attributes",
                               analytics: environment.analytics)
        case .loading(.done(let request, let callback)):
            state = .loaded(IdentificationOverviewLoadedState(id: environment.uuidFactory(),
                                                              request: request,
                                                              handler: callback,
                                                              canGoBackToSetupIntro: state.canGoBackToSetupIntro))
            return .none
        default:
            return .none
        }
    }
)

struct IdentificationOverview: View {
    
    var store: Store<IdentificationOverviewState, IdentificationOverviewAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            SwitchStore(store) {
                CaseLet(state: /IdentificationOverviewState.loading,
                        action: IdentificationOverviewAction.loading) { loadingStore in
                    IdentificationOverviewLoading(store: loadingStore)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                CaseLet(state: /IdentificationOverviewState.loaded,
                        action: IdentificationOverviewAction.loaded) { loadedStore in
                    IdentificationOverviewLoaded(store: loadedStore)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                CaseLet(state: /IdentificationOverviewState.error,
                        action: IdentificationOverviewAction.error) { errorStore in
                    DialogView(store: errorStore.stateless,
                               title: L10n.Identification.FetchMetadataError.title,
                               message: L10n.Identification.FetchMetadataError.body,
                               primaryButton: .init(title: L10n.Identification.FetchMetadataError.retry, action: .retry))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(viewStore.canGoBackToSetupIntro ? L10n.General.back : L10n.Identification.end) {
                        ViewStore(store.stateless).send(viewStore.canGoBackToSetupIntro ? .back : .end)
                    }
                }
            }
        }
    }
}

#if PREVIEW
let demoTokenURL = URL(string: "bundesident://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%3A443%2FAutent-DemoApplication%2FWebServiceRequesterServlet%3Fdummy%3Dfalse%26useCan%3Dfalse%26ta%3Dfalse")!
#endif

struct IdentificationOverview_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationOverview(store: .init(initialState: IdentificationOverviewState.loading(IdentificationOverviewLoadingState(canGoBackToSetupIntro: false)),
                                            reducer: identificationOverviewReducer,
                                            environment: AppEnvironment.preview))
    }
}
