import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct IdentificationOverviewLoadedState: Identifiable, Equatable {
    let id: UUID
    let request: EIDAuthenticationRequest
    var handler: IdentifiableCallback<FlaggedAttributes>
    
    var requiredReadAttributes: IdentifiedArrayOf<IDCardAttribute> {
        let requiredAttributes = request.readAttributes.compactMap { (key: IDCardAttribute, isRequired: Bool) in
            isRequired ? key : nil
        }
        return IdentifiedArrayOf(uniqueElements: requiredAttributes)
    }
}

enum IdentificationOverviewState: Equatable, IDInteractionHandler {
    case loading(IdentificationOverviewLoadingState)
    case loaded(IdentificationOverviewLoadedState)
    case error(IdentifiableError)
    
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

enum IdentificationOverviewLoadedAction: Equatable {
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case moreInfo
    case callbackReceived(EIDAuthenticationRequest, PINCallback)
    case done
    case failure(IdentifiableError)
}

enum IdentificationOverviewErrorAction: Equatable {
    case retry
}

typealias PINCallback = IdentifiableCallback<String>

enum IdentificationOverviewAction: Equatable {
    case loading(IdentificationOverviewLoadingAction)
    case loaded(IdentificationOverviewLoadedAction)
    case error(IdentificationOverviewErrorAction)
    
    case onAppear
    case cancel
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
            state = .loading(IdentificationOverviewLoadingState())
            return Effect(value: .loading(.identify))
        case .loading(.failure(let error)):
            state = .error(error)
            return .trackEvent(category: "identification",
                               action: "loadingFailed",
                               name: "attributes",
                               analytics: environment.analytics)
        case .loading(.done(let request, let callback)):
            state = .loaded(IdentificationOverviewLoadedState(id: environment.uuidFactory(),
                                                              request: request,
                                                              handler: callback))
            return .none
        default:
            return .none
        }
    }
)

struct IdentificationOverview: View {
    
    var store: Store<IdentificationOverviewState, IdentificationOverviewAction>
    
    var body: some View {
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
                Button(L10n.Identification.end) {
                    ViewStore(store.stateless).send(.cancel)
                }
            }
        }
    }
}

let demoTokenURL = "eid://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%3A443%2FAutent-DemoApplication%2FWebServiceRequesterServlet%3Fdummy%3Dfalse%26useCan%3Dfalse%26ta%3Dfalse"

struct IdentificationOverview_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationOverview(store: .init(initialState: IdentificationOverviewState.loading(IdentificationOverviewLoadingState()),
                                            reducer: identificationOverviewReducer,
                                            environment: AppEnvironment.preview))
    }
}
