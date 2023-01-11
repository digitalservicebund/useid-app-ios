import ComposableArchitecture
import Foundation
import SwiftUI

struct IdentificationHandOff: ReducerProtocol {
    
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.logger) var logger
    @Dependency(\.apiController) var apiController
    
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
            let request = state.request
            let redirectURL = state.redirectURL
            let sessionId = state.identificationInformation.widgetSessionId
            
            return .task {
                do {
                    try await apiController.sendSessionEvent(sessionId: sessionId, redirectURL: redirectURL)
                    return .refreshed(success: true, request: request, redirectURL: redirectURL)
                } catch {
                    return .refreshed(success: false, request: request, redirectURL: redirectURL)
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
