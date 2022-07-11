import ComposableArchitecture
import SwiftUI

enum IdentificationOverviewLoadingAction: Equatable {
    case onAppear
    case idInteractionEvent(Result<EIDInteractionEvent, IDCardInteractionError>)
    case done(EIDAuthenticationRequest, IdentifiableCallback<FlaggedAttributes>)
    case failure(IdentifiableError)
}

let identificationOverviewLoadingReducer = Reducer<Void, IdentificationOverviewLoadingAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        return .none
    case .idInteractionEvent(.success(.requestAuthenticationRequestConfirmation(let request, let handler))):
        return Effect(value: .done(request, IdentifiableCallback(id: environment.uuidFactory(), callback: handler)))
    case .idInteractionEvent(.failure(let error)):
        return Effect(value: .failure(IdentifiableError(error)))
    case .idInteractionEvent:
        return .none
    case .done:
        return .none
    case .failure:
        return .none
    }
}

struct IdentificationOverviewLoading: View {
    var store: Store<Void, IdentificationOverviewLoadingAction>
    
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.blue900))
                .scaleEffect(3)
                .frame(maxWidth: .infinity)
                .padding(50)
            Text(L10n.Identification.Overview.loading)
                .font(.bundBody)
                .foregroundColor(.blackish)
                .padding(.bottom, 50)
        }
        .onAppear {
            ViewStore(store.stateless).send(.onAppear)
        }
    }
}
