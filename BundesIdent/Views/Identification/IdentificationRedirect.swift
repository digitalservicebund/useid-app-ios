import Foundation
import SwiftUI
import ComposableArchitecture



struct IdentificationContinue: ReducerProtocol {
    
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.logger) var logger
    
    struct State: Equatable {
        var request: EIDAuthenticationRequest
        var redirectURL: URL
        var alert: AlertState<Action>?
    }
    
    enum Action: Equatable {
        case open(request: EIDAuthenticationRequest)
        case refresh
        case refreshed(success: Bool, request: EIDAuthenticationRequest)
        case share
        case shared(request: EIDAuthenticationRequest)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .open:
            return .openURL(state.redirectURL, urlOpener: urlOpener)
        case .refresh:
            struct Payload: Codable {
                let refreshAddress: String
            }
            
            let request = state.request
            let lastPathComponent = "success" // state.success ? "success" : "error"
            let payload = Payload(refreshAddress: state.redirectURL.absoluteString)
            
            return .run { send in
                do {
                    let data = try JSONEncoder().encode(payload)
                    let sessionId = "3f57aa36-f94d-481f-9077-c20cf34d7ab9"
                    let url = URL(string: "https://useid.dev.ds4g.net/api/v1/events/\(sessionId)/\(lastPathComponent)")!
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.httpBody = data
                    _ = try await URLSession.shared.data(for: urlRequest)
                    await send(.refreshed(success: true, request: request))
                } catch {
                    logger.error("Error sending event to server: \(error)")
                    await send(.refreshed(success: false, request: request))
                }
            }
        case .refreshed(success: true, request: _):
            return .none
        case .refreshed(success: false, request: _):
            state.alert = .init(title: TextState("Refresh of website failed"))
            return .none
        case .share:
            return .none
        case .shared:
            return .none
        }
    }
}

struct IdentificationContinueView: View {
    let store: StoreOf<IdentificationContinue>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.Identification.Continue.title,
                       message: L10n.Identification.Continue.message(viewStore.request.subject),
                       imageMeta: nil,
                       secondaryButton: .init(title: L10n.Identification.Continue.refresh, action: .refresh),
                       primaryButton: .init(title: L10n.Identification.Continue.open, action: .open(request: viewStore.request)))
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(false)
        }
    }
}
