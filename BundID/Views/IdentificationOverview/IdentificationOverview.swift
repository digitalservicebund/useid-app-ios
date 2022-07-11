import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct IdentificationOverviewLoadedState: Identifiable, Equatable {
    let id: UUID
    let request: EIDAuthenticationRequest
    let handler: IdentifiableCallback<FlaggedAttributes>
    
#if PREVIEW
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    
    static func == (lhs: IdentificationOverviewLoadedState, rhs: IdentificationOverviewLoadedState) -> Bool {
        return lhs.id == rhs.id && lhs.request == rhs.request
    }
    
    var requiredReadAttributes: IdentifiedArrayOf<IDCardAttribute> {
        let requiredAttributes = request.readAttributes.compactMap { (key: IDCardAttribute, isRequired: Bool) in
            isRequired ? key : nil
        }
        return IdentifiedArrayOf(uniqueElements: requiredAttributes)
    }
}

enum IdentificationOverviewTokenFetch: Equatable, IDInteractionHandler {
    case loading
    case loaded(IdentificationOverviewLoadedState)
    case error(IdentifiableError)
    
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> TokenFetchAction? {
        switch self {
        case .loading:
            return .loading(.idInteractionEvent(event))
        case .loaded(let identificationOverviewLoadedState):
            return nil
        case .error(let identifiableError):
            return nil
        }
    }
}

struct IdentificationOverviewState: Equatable, IDInteractionHandler {
    var tokenFetch: IdentificationOverviewTokenFetch = .loading
#if PREVIEW
    var availableDebugActions: [IdentifyDebugSequence] = []
#endif
    
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationOverviewAction? {
        guard let subAction = tokenFetch.transformToLocalAction(event) else { return nil }
        return .tokenFetch(subAction)
    }
}

enum TokenFetchLoadedAction: Equatable {
    case `continue`
    case moreInfo
}

enum TokenFetchErrorAction: Equatable {
    case retry
}

enum TokenFetchAction: Equatable {
    case loading(IdentificationOverviewLoadingAction)
    case loaded(TokenFetchLoadedAction)
    case error(TokenFetchErrorAction)
}

typealias PINCallback = IdentifiableCallback<String>

enum IdentificationOverviewAction: Equatable {
    case onAppear
    case identify
    case cancel
    case tokenFetch(TokenFetchAction)
    case callbackReceived(EIDAuthenticationRequest, PINCallback)
#if PREVIEW
    case runDebugSequence(IdentifyDebugSequence)
#endif
}

let tokenFetchReducer = Reducer<IdentificationOverviewTokenFetch, TokenFetchAction, AppEnvironment>.combine(
    identificationOverviewLoadingReducer.pullback(state: /IdentificationOverviewTokenFetch.loading,
                                                  action: /TokenFetchAction.loading,
                                                  environment: { $0 })
)

let identificationOverviewReducer = Reducer<IdentificationOverviewState, IdentificationOverviewAction, AppEnvironment>.combine(
    tokenFetchReducer.pullback(state: \.tokenFetch, action: /IdentificationOverviewAction.tokenFetch, environment: { $0 }),
    Reducer { state, action, environment in
        switch action {
        case .tokenFetch(.loading(.onAppear)):
            return Effect(value: .identify)
        case .tokenFetch(.error(.retry)):
            state.tokenFetch = .loading
            return Effect(value: .identify)
        case .tokenFetch(.loading(.failure(let error))):
            state.tokenFetch = .error(error)
            return .none
        case .tokenFetch(.loading(.done(let request, let callback))):
            state.tokenFetch = .loaded(IdentificationOverviewLoadedState(id: environment.uuidFactory(), request: request, handler: callback))
            return .none
        case .tokenFetch(.loaded(.continue)):
            guard case .loaded(let subState) = state.tokenFetch else { return .none } // TODO: subreducer for state loaded
            var dict: [IDCardAttribute: Bool] = [:]
            for attribute in subState.requiredReadAttributes {
                dict[attribute] = true
            }
            subState.handler(dict)
            return .none
        case .callbackReceived:
            return .none
        default:
            return .none
        }
    }
)

extension IdentificationOverviewState {
    mutating func handle(event: EIDInteractionEvent, environment: AppEnvironment) -> Effect<IdentificationOverviewAction, Never> {
        switch event {
        case .requestPIN(remainingAttempts: nil, pinCallback: let handler):
            guard case .loaded(let subState) = tokenFetch else { return .none } // TODO: Move to subreducer
            return Effect(value: .callbackReceived(subState.request, PINCallback(id: environment.uuidFactory(), callback: handler)))
        default:
            return .none
        }
    }
}

struct IdentificationOverview: View {
    
    var store: Store<IdentificationOverviewState, IdentificationOverviewAction>
    
    var body: some View {
        SwitchStore(store.scope(state: \.tokenFetch, action: IdentificationOverviewAction.tokenFetch)) {
            CaseLet(state: /IdentificationOverviewTokenFetch.loading,
                    action: TokenFetchAction.loading) { loadingStore in
                IdentificationOverviewLoading(store: loadingStore)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            CaseLet(state: /IdentificationOverviewTokenFetch.loaded,
                    action: TokenFetchAction.loaded) { loadedStore in
                IdentificationOverviewLoaded(store: loadedStore)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            CaseLet(state: /IdentificationOverviewTokenFetch.error,
                    action: TokenFetchAction.error) { errorStore in
                // TODO: Own error view
                DialogView(store: errorStore.stateless,
                           title: L10n.Identification.Overview.Error.title,
                           message: L10n.Identification.Overview.Error.body,
                           primaryButton: .init(title: L10n.Identification.Overview.Error.retry, action: .retry))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(L10n.General.cancel) {
                    ViewStore(store.stateless).send(.cancel)
                }
            }
        }
        .toolbar {
#if PREVIEW
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

let demoTokenURL = "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%3A443%2FAutent-DemoApplication%2FWebServiceRequesterServlet%3Fdummy%3Dfalse%26useCan%3Dfalse%26ta%3Dfalse"

struct IdentificationOverview_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationOverview(store: .init(initialState: IdentificationOverviewState(),
                                            reducer: identificationOverviewReducer,
                                            environment: AppEnvironment.preview))
    }
}
