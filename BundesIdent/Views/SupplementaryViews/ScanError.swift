import SwiftUI
import Analytics
import ComposableArchitecture

enum ScanErrorType: Equatable {
    case cardDeactivated
    case cardBlocked
    case help
    case idCardInteraction(IDCardInteractionError)
    case unexpectedEvent(EIDInteractionEvent)
}

struct ScanError: ReducerProtocol {
    @Dependency(\.urlOpener) var urlOpener
    struct State: Equatable {
        var errorType: ScanErrorType
        var retry: Bool
        
        var title: String {
            switch errorType {
            case .cardDeactivated:
                return L10n.ScanError.CardDeactivated.title
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
            case .cardBlocked:
                return L10n.ScanError.CardBlocked.body
            case .idCardInteraction,
                 .unexpectedEvent,
                 .help:
                return L10n.ScanError.CardUnreadable.body
            }
        }
        
        var primaryButton: DialogButtons<ScanError.Action>.ButtonConfiguration {
            if retry {
                return .init(title: L10n.ScanError.close, action: .retry)
            } else if case .idCardInteraction(.processFailed(_, let url, _)) = errorType, let url {
                return .init(title: L10n.ScanError.redirect, action: .end(redirectURL: url))
            } else {
                return .init(title: L10n.ScanError.close, action: .end(redirectURL: nil))
            }
        }
        
        var boxContent: BoxContent? {
            guard !retry else { return nil }
            
            switch errorType {
            case .cardDeactivated, .cardBlocked, .help, .idCardInteraction(.cardDeactivated), .idCardInteraction(.cardBlocked):
                return nil
            case .idCardInteraction, .unexpectedEvent:
                return .init(title: L10n.ScanError.Box.title, message: L10n.ScanError.Box.body, style: .error)
            }
        }
    }
    
    enum Action: Equatable {
        case end(redirectURL: URL?)
        case retry
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .end(let redirectURL):
            guard let redirectURL else { return .none }
            return .openURL(redirectURL, urlOpener: urlOpener)
        default:
            return .none
        }
    }
}

extension ScanErrorType: AnalyticsView {
    var route: [String] {
        switch self {
        case .help:
            return ["scanHelp"]
        case .cardDeactivated:
            return ["cardDeactivated"]
        case .cardBlocked:
            return ["cardBlocked"]
        case .idCardInteraction, .unexpectedEvent:
            return ["cardUnreadable"]
        }
    }
}

struct ScanErrorView: View {
    var store: Store<ScanError.State, ScanError.Action>
    
    var body: some View {
        NavigationView {
            WithViewStore(store) { viewStore in
                DialogView(store: store.stateless,
                           title: viewStore.title,
                           boxContent: viewStore.boxContent,
                           message: viewStore.markdown,
                           primaryButton: viewStore.primaryButton)
                    .interactiveDismissDisabled(true)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(false)
        }
    }
}

struct SetupError_Previews: PreviewProvider {
    static var previews: some View {
        ScanErrorView(store: Store(initialState: .init(errorType: .cardDeactivated, retry: false),
                                   reducer: ScanError()))
        ScanErrorView(store: Store(initialState: .init(errorType: .cardBlocked, retry: false),
                                   reducer: ScanError()))
        ScanErrorView(store: Store(initialState: .init(errorType: .unexpectedEvent(.cardRemoved), retry: true),
                                   reducer: ScanError()))
    }
}
