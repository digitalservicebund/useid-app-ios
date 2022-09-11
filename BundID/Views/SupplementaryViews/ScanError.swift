import SwiftUI
import ComposableArchitecture

enum ScanErrorType: Equatable {
    case cardDeactivated
    case cardSuspended
    case cardBlocked
    case help
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct ScanErrorState: Equatable {
    var errorType: ScanErrorType
    var retry: Bool
    
    var title: String {
        switch errorType {
        case .cardDeactivated:
            return L10n.ScanError.CardDeactivated.title
        case .cardSuspended:
            return L10n.ScanError.CardSuspended.title
        case .cardBlocked:
            return L10n.ScanError.CardBlocked.title
        case .idCardInteraction,
                .unexpectedEvent,
                .help:
            return L10n.ScanError.CardUnreadable.title
        }
    }
    
    var markdown: String {
        switch errorType {
        case .cardDeactivated:
            return L10n.ScanError.CardDeactivated.body
        case .cardSuspended:
            return L10n.ScanError.CardSuspended.body
        case .cardBlocked:
            return L10n.ScanError.CardBlocked.body
        case .idCardInteraction,
                .unexpectedEvent,
                .help:
            return L10n.ScanError.CardUnreadable.body
        }
    }
}

enum ScanErrorAction: Equatable {
    case end
    case retry
}

struct ScanError: View {
    var store: Store<ScanErrorState, ScanErrorAction>
    
    var body: some View {
        NavigationView {
            WithViewStore(store) { viewStore in
                DialogView(store: store.stateless,
                           title: viewStore.title,
                           message: viewStore.markdown,
                           primaryButton: .init(title: L10n.ScanError.close,
                                                action: viewStore.retry ? .retry : .end))
                .interactiveDismissDisabled(!viewStore.retry)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(false)
        }
    }
}

struct SetupError_Previews: PreviewProvider {
    static var previews: some View {
        ScanError(store: Store(initialState: .init(errorType: .cardDeactivated, retry: false),
                                reducer: .empty,
                                environment: AppEnvironment.preview))
        ScanError(store: Store(initialState: .init(errorType: .cardSuspended, retry: false),
                                reducer: .empty,
                                environment: AppEnvironment.preview))
        ScanError(store: Store(initialState: .init(errorType: .cardBlocked, retry: false),
                                reducer: .empty,
                                environment: AppEnvironment.preview))
        ScanError(store: Store(initialState: .init(errorType: .unexpectedEvent(.cardRemoved), retry: true),
                               reducer: .empty,
                               environment: AppEnvironment.preview))
    }
}
