import Foundation
import SwiftUI
import ComposableArchitecture

struct IdentificationHandOff: ReducerProtocol {
    
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.logger) var logger
    
    struct State: Equatable {
        var identificationInformation: IdentificationInformation
        var request: EIDAuthenticationRequest
        var redirectURL: URL
    }
    
    enum Action: Equatable {
        case open(request: EIDAuthenticationRequest)
        case refresh
        case refreshed(success: Bool, request: EIDAuthenticationRequest, redirectURL: URL)
    }
    
    enum Error: Swift.Error, Equatable {
        case invalidURL
        case invalidURLResponse
        case unexpectedStatusCode(Int)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .open:
            return .openURL(state.redirectURL, urlOpener: urlOpener)
        case .refresh:
            struct Payload: Codable {
                let refreshAddress: String
            }
            
            // TODO: Extract that logic later
            let request = state.request
            let redirectURL = state.redirectURL
            let sessionId = state.identificationInformation.sessionId
            let payload = Payload(refreshAddress: state.redirectURL.absoluteString)
            
            return .run { send in
                do {
                    let data = try JSONEncoder().encode(payload)
                    guard let url = URL(string: "https://eid.digitalservicebund.de/api/v1/events/\(sessionId)/success") else {
                        throw Error.invalidURL
                    }
                    var urlRequest = URLRequest(url: url)
                    urlRequest.httpMethod = "POST"
                    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    urlRequest.httpBody = data
                    let (_, response) = try await URLSession.shared.data(for: urlRequest)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw Error.invalidURLResponse
                    }
                    
                    guard httpResponse.statusCode == 202 else {
                        throw Error.unexpectedStatusCode(httpResponse.statusCode)
                    }
                    
                    await send(.refreshed(success: true, request: request, redirectURL: redirectURL))
                } catch {
                    logger.error("Error sending event to server: \(error)")
                    await send(.refreshed(success: false, request: request, redirectURL: redirectURL))
                }
            }
        case .refreshed:
            return .none
        }
    }
}

struct IdentificationHandOffView: View {
    let store: StoreOf<IdentificationHandOff>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.Identification.HandOff.title,
                       message: L10n.Identification.HandOff.message(viewStore.request.subject),
                       imageMeta: nil,
                       secondaryButton: .init(title: L10n.Identification.HandOff.handOff, action: .refresh),
                       primaryButton: .init(title: L10n.Identification.HandOff.open, action: .open(request: viewStore.request)))
            .navigationBarBackButtonHidden(true)
            .navigationBarHidden(false)
        }
    }
}
