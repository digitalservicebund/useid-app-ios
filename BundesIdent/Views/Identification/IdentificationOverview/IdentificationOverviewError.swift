import ComposableArchitecture
import Foundation
import SwiftUI

struct IdentificationOverviewError: ReducerProtocol {
    
    struct State: Equatable {
        let error: IdentifiableError
        let identificationInformation: IdentificationInformation
        let canGoBackToSetupIntro: Bool
        
        let expirationChecked: Bool
        let transactionInfo: TransactionInfo?
        
        init(error: IdentifiableError, identificationInformation: IdentificationInformation, canGoBackToSetupIntro: Bool = false, expirationChecked: Bool, transactionInfo: TransactionInfo?) {
            self.error = error
            self.identificationInformation = identificationInformation
            self.canGoBackToSetupIntro = canGoBackToSetupIntro
            self.expirationChecked = expirationChecked
            self.transactionInfo = transactionInfo
        }
        
        var tokenIsInvalid: Bool {
            if let identificationError = error.error as? IdentificationOverviewLoadingError,
               identificationError == .invalidToken {
                return true
            } else {
                return false
            }
        }
        
        var title: String {
            if tokenIsInvalid {
                return L10n.Identification.ExpiredTokenError.title
            } else {
                return L10n.Identification.FetchMetadataError.title
            }
        }
        
        var body: String {
            if tokenIsInvalid {
                return L10n.Identification.ExpiredTokenError.body
            } else {
                return L10n.Identification.FetchMetadataError.body
            }
        }
        
        var primaryButton: DialogButtons<Action>.ButtonConfiguration? {
            if tokenIsInvalid {
                return .init(title: L10n.Identification.ExpiredTokenError.close, action: .close)
            } else {
                return .init(title: L10n.Identification.FetchMetadataError.retry, action: .retry(expirationChecked: expirationChecked, transactionInfo: transactionInfo))
            }
        }
    }
    
    enum Action: Equatable {
        case retry(expirationChecked: Bool, transactionInfo: TransactionInfo?)
        case close
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
                       primaryButton: viewStore.primaryButton)
        }
    }
}

struct IdentificationOverviewErrorView_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationOverviewErrorView(store: StoreOf<IdentificationOverviewError>(initialState: .init(error: IdentifiableError(HandleURLError.tcTokenURLCreationFailed), identificationInformation: .preview, expirationChecked: false, transactionInfo: nil),
                                                                                    reducer: EmptyReducer()))
    }
}
