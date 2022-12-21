import Combine
import ComposableArchitecture
import SwiftUI

struct IdentificationDone: ReducerProtocol {
    struct State: Equatable {
        let request: EIDAuthenticationRequest
    }
    
    enum Action: Equatable {
        case close
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct IdentificationDoneView: View {
    let store: StoreOf<IdentificationDone>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.Identification.Done.title,
                       message: L10n.Identification.Done.message(viewStore.request.subject),
                       imageMeta: nil,
                       secondaryButton: nil,
                       primaryButton: .init(title: L10n.Identification.Done.close, action: .close))
        }
    }
}
