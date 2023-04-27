import SwiftUI
import Analytics
import ComposableArchitecture
import TCACoordinators

typealias PINCallback = IdentifiableCallback<String>
typealias PINCANCallback = IdentifiableCallback<(String, String)>

struct IdentificationOverview: ReducerProtocol {
    @Dependency(\.uuid) var uuid
    @Dependency(\.analytics) var analytics
    enum State: Equatable, EIDInteractionHandler {
        case loading(IdentificationOverviewLoading.State)
        case loaded(IdentificationOverviewLoaded.State)
        case error(IdentificationOverviewErrorState)
        
        func transformToLocalAction(_ event: Result<EIDInteractionEvent, EIDInteractionError>) -> Action? {
            switch self {
            case .loading:
                return .loading(.eIDInteractionEvent(event))
            case .loaded:
                return nil
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
    
    enum Action: Equatable {
        case loading(IdentificationOverviewLoading.Action)
        case loaded(IdentificationOverviewLoaded.Action)
        case error(IdentificationOverviewErrorAction)
        
        case onAppear
        case end
        case back
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.loading, action: /Action.loading) {
            IdentificationOverviewLoading()
        }
        Scope(state: /State.loaded, action: /Action.loaded) {
            IdentificationOverviewLoaded()
        }
        Reduce { state, action in
            switch action {
            case .error(.retry):
                state = .loading(IdentificationOverviewLoading.State(canGoBackToSetupIntro: state.canGoBackToSetupIntro))
                return .none
            case .loading(.failure(let error)):
                state = .error(IdentificationOverviewErrorState(error: error, canGoBackToSetupIntro: state.canGoBackToSetupIntro))
                return .trackEvent(category: "identification",
                                   action: "loadingFailed",
                                   name: "attributes",
                                   analytics: analytics)
            case .loading(.done(let request, let certificateDescription)):
                let identificationInformation = IdentificationInformation(request: request,
                                                                          certificateDescription: certificateDescription)
                state = .loaded(IdentificationOverviewLoaded.State(id: uuid.callAsFunction(),
                                                                   identificationInformation: identificationInformation,

                                                                   canGoBackToSetupIntro: state.canGoBackToSetupIntro))
                return .none
            default:
                return .none
            }
        }
    }
}

struct IdentificationOverviewView: View {
    
    var store: Store<IdentificationOverview.State, IdentificationOverview.Action>
    var body: some View {
        WithViewStore(store) { viewStore in
            SwitchStore(store) {
                CaseLet(state: /IdentificationOverview.State.loading,
                        action: IdentificationOverview.Action.loading) { loadingStore in
                    IdentificationOverviewLoadingView(store: loadingStore)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                CaseLet(state: /IdentificationOverview.State.loaded,
                        action: IdentificationOverview.Action.loaded) { loadedStore in
                    IdentificationOverviewLoadedView(store: loadedStore)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                CaseLet(state: /IdentificationOverview.State.error,
                        action: IdentificationOverview.Action.error) { errorStore in
                    DialogView(store: errorStore.stateless,
                               title: L10n.Identification.FetchMetadataError.title,
                               message: L10n.Identification.FetchMetadataError.body,
                               primaryButton: .init(title: L10n.Identification.FetchMetadataError.retry, action: .retry))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewStore.canGoBackToSetupIntro {
                        BackButton {
                            ViewStore(store.stateless).send(.back)
                        }
                    } else {
                        Button(L10n.Identification.end) {
                            ViewStore(store.stateless).send(.end)
                        }
                        .bodyLRegular(color: .accentColor)
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
        IdentificationOverviewView(store: .init(initialState: IdentificationOverview.State.loading(IdentificationOverviewLoading.State(canGoBackToSetupIntro: false)),
                                                reducer: IdentificationOverview()))
    }
}
