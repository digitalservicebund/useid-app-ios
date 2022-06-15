import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct IdentificationOverviewLoadedState: Identifiable, Equatable {
    let id: UUID
    let request: EIDAuthenticationRequest
    let handler: (FlaggedAttributes) -> Void
    
    static func ==(lhs: IdentificationOverviewLoadedState, rhs: IdentificationOverviewLoadedState) -> Bool {
        return lhs.id == rhs.id && lhs.request == rhs.request
    }
    
    var requiredReadAttributes: IdentifiedArrayOf<IDCardAttribute> {
        let requiredAttributes = request.readAttributes.compactMap { (key: IDCardAttribute, isRequired: Bool) in
            isRequired ? key : nil
        }
        return IdentifiedArrayOf(uniqueElements: requiredAttributes)
    }
}

enum IdentificationOverviewTokenFetch: Equatable {
    case loading
    case loaded(IdentificationOverviewLoadedState)
    case error(IdentifiableError)
}

struct IdentificationOverviewState: Equatable {
    var tokenURL: String
    var tokenFetch: IdentificationOverviewTokenFetch = .loading
}

enum TokenFetchLoadingAction: Equatable {
    case done(Result<IdentificationOverviewLoadedState, IdentifiableError>)
}

enum TokenFetchLoadedAction: Equatable {
    case `continue`
    case moreInfo
}

enum TokenFetchErrorAction: Equatable {
    case retry
}

enum TokenFetchAction: Equatable {
    case loading(TokenFetchLoadingAction)
    case loaded(TokenFetchLoadedAction)
    case error(TokenFetchErrorAction)
}

enum IdentificationOverviewAction: Equatable {
    case onAppear
    case identify
    case cancel
    case tokenFetch(TokenFetchAction)
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case done
}

let identificationOverviewReducer = Reducer<IdentificationOverviewState, IdentificationOverviewAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        guard state.tokenFetch == .loading else { return .none }
        return Effect(value: .identify)
    case .identify:
        return environment.idInteractionManager.identify(tokenURL: state.tokenURL)
            .receive(on: environment.mainQueue)
            .catchToEffect(IdentificationOverviewAction.idInteractionEvent)
            .cancellable(id: "Identify", cancelInFlight: true)
    case .idInteractionEvent(.success(let event)):
        switch event {
        case .requestAuthenticationRequestConfirmation(let request, let handler):
            state.tokenFetch = .loaded(IdentificationOverviewLoadedState(id: environment.uuidFactory(), request: request, handler: handler))
            return .none
        default:
            return .none
        }
    case .idInteractionEvent(.failure(let error)):
        state.tokenFetch = .error(IdentifiableError(error))
        return .none
    case .tokenFetch(.error(.retry)):
        state.tokenFetch = .loading
        return Effect(value: .identify)
    default:
        return .none
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
                DialogView(store: errorStore.stateless,
                           title: L10n.Identification.Overview.Error.title,
                           message: L10n.Identification.Overview.Error.body,
                           primaryButton: .init(title: L10n.Identification.Overview.Error.retry, action: .retry))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            ViewStore(store).send(.onAppear)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(L10n.General.cancel) {
                    ViewStore(store.stateless).send(.cancel)
                }
            }
        }
    }
}

let demoTokenURL = "http://127.0.0.1:24727/eID-Client?tcTokenURL=https%3A%2F%2Ftest.governikus-eid.de%3A443%2FAutent-DemoApplication%2FWebServiceRequesterServlet%3Fdummy%3Dfalse%26useCan%3Dfalse%26ta%3Dfalse"

struct IdentificationOverview_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationOverview(store: .init(initialState: IdentificationOverviewState(tokenURL: demoTokenURL),
                                            reducer: identificationOverviewReducer,
                                            environment: AppEnvironment.preview))
    }
}
