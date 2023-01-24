import AuthenticationServices
import ComposableArchitecture
import Foundation
import SwiftUI

struct IdentificationHandOff: ReducerProtocol {
    
    @Dependency(\.urlOpener) var urlOpener
    @Dependency(\.logger) var logger
    @Dependency(\.apiController) var apiController
    @Dependency(\.webAuthenticationManager) var webAuthenticationManager
    
    struct State: Equatable {
        var identificationInformation: IdentificationInformation
        var request: EIDAuthenticationRequest
        var redirectURL: URL
        var alert: AlertState<Action>?
    }
    
    enum Action: Equatable {
        case open(request: EIDAuthenticationRequest)
        case webauthn
        case registrationCompleted
        case registrationFailed(IdentifiableError)
        case refresh
        case refreshed(success: Bool, request: EIDAuthenticationRequest, redirectURL: URL)
        case dismissAlert
    }
    
    enum Error: Swift.Error, Equatable {
        case invalidURL
        case invalidURLResponse
        case missingRawAttestationObject
        case unexpectedStatusCode(Int)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .open:
            return .openURL(state.redirectURL, urlOpener: urlOpener)
        case .webauthn:
            let redirectURL = state.redirectURL
            let widgetSessionId = state.identificationInformation.widgetSessionId
            let window = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first!
            return .task {
                let initiatingResponse = try await apiController.initiateRegistration()
                let generatedCredentials = try await webAuthenticationManager.registerWith(
                    userId: initiatingResponse.userId,
                    widgetSessionId: widgetSessionId,
                    host: "useid.dev.ds4g.net",
                    challenge: initiatingResponse.challenge,
                    anchor: window
                )
                guard let rawAttestationObject = generatedCredentials.rawAttestationObject else {
                    throw Error.missingRawAttestationObject
                }
                let registrationDetails = RegistrationDetails(
                    rawAttestationObject: rawAttestationObject,
                    rawClientDataJSON: generatedCredentials.rawClientDataJSON,
                    credentialId: generatedCredentials.credentialID
                )
                try await apiController.completeRegistration(
                    userId: initiatingResponse.userId,
                    widgetSessionId: widgetSessionId,
                    registrationDetails: registrationDetails,
                    refreshURL: redirectURL
                )
                return .registrationCompleted
            } catch: { error in
                .registrationFailed(IdentifiableError(error))
            }
        case .registrationFailed(let error):
            state.alert = AlertState(
                title: TextState(L10n.Identification.FetchMetadataError.title),
                message: TextState(error.localizedDescription)
            )
            return .none
        case .registrationCompleted:
            return .none
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
        case .dismissAlert:
            state.alert = nil
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
                       secondaryButton: .init(title: L10n.Identification.HandOff.handOff, action: .webauthn),
                       primaryButton: .init(title: L10n.Identification.HandOff.open, action: .open(request: viewStore.request)))
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(false)
        }
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}
