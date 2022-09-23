import SwiftUI
import Analytics
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
    
    var primaryButton: DialogButtons<ScanErrorAction>.ButtonConfiguration {
        if retry {
            return .init(title: L10n.ScanError.close,  action: .retry)
        } else if case .idCardInteraction(.processFailed(_, let urlString)) = errorType,
                  let url = urlString.flatMap(URL.init(string:)) {
            return .init(title: L10n.ScanError.redirect, action: .end(redirectURL: url))
        } else {
            return .init(title: L10n.ScanError.close, action: .end(redirectURL: nil))
        }
    }
    
    var boxContent: BoxContent? {
        guard !retry else { return  nil }
        return .init(title: L10n.ScanError.Box.title, message: L10n.ScanError.Box.body, style: .error)
    }
}

enum ScanErrorAction: Equatable {
    case end(redirectURL: URL?)
    case retry
}

let scanErrorReducer = Reducer<ScanErrorState, ScanErrorAction, AppEnvironment> { _, action, environment in
    switch action {
    case .end(let redirectURL):
        guard let redirectURL else { return .none }
        return .openURL(redirectURL, urlOpener: environment.urlOpener)
    default:
        return .none
    }
}

extension ScanErrorType: AnalyticsView {
    var route: [String] {
        switch self {
        case .help:
            return ["scanHelp"]
        case .cardDeactivated:
            return ["cardDeactivated"]
        case .cardSuspended:
            return ["cardSuspended"]
        case .cardBlocked:
            return ["cardBlocked"]
        case .idCardInteraction, .unexpectedEvent:
            return ["cardUnreadable"]
        }
    }
}

struct ScanError: View {
    var store: Store<ScanErrorState, ScanErrorAction>
    
    var body: some View {
        NavigationView {
            WithViewStore(store) { viewStore in
                DialogView(store: store.stateless,
                           title: viewStore.title,
                           boxContent: viewStore.boxContent,
                           message: viewStore.markdown,
                           primaryButton: viewStore.primaryButton)
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
