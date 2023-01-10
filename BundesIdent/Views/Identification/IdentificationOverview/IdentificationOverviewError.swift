import ComposableArchitecture
import Foundation
import SwiftUI

struct IdentificationOverviewError: ReducerProtocol {
    
    struct State: Equatable {
        let error: IdentifiableError
        let canGoBackToSetupIntro: Bool
        
        init(error: IdentifiableError, canGoBackToSetupIntro: Bool = false) {
            self.error = error
            self.canGoBackToSetupIntro = canGoBackToSetupIntro
        }
        
        var title: String {
            // TODO: Check if error was because of http error 410 Gone
            L10n.Identification.FetchMetadataError.title
        }
        
        var body: String {
            L10n.Identification.FetchMetadataError.body
        }
    }
    
    enum Action: Equatable {
        case retry
    }
    
    var body: some ReducerProtocol<State, Action> {
        EmptyReducer()
    }
    
}

struct IdentificationOverviewErrorView: View {
    let store: StoreOf<IdentificationOverviewError>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: viewStore.title,
                       message: viewStore.body,
                       primaryButton: .init(title: L10n.Identification.FetchMetadataError.retry, action: .retry))
        }
    }
}

struct IdentificationOverviewErrorView_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationOverviewErrorView(store: StoreOf<IdentificationOverviewError>(initialState: .init(error: IdentifiableError(HandleURLError.tcTokenURLCreationFailed)),
                                                                                    reducer: EmptyReducer()))
    }
}
