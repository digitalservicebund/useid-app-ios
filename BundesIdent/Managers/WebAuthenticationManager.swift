import AuthenticationServices
import Foundation
import OSLog

enum WebAuthenticationManagerError: Error {
    case alreadyRegistering
    case invalidUserId
    case invalidAuthorizationType
    case canceled
}

protocol WebAuthenticationManagerType {
    func registerWith(userId: String, widgetSessionId: String, host: String, challenge: Data, anchor: ASPresentationAnchor) async throws -> ASAuthorizationPlatformPublicKeyCredentialRegistration
}

class WebAuthenticationManager: NSObject, WebAuthenticationManagerType, ASAuthorizationControllerPresentationContextProviding, ASAuthorizationControllerDelegate {
    
    var logger: Logger
    
    init(logger: Logger) {
        self.logger = logger
    }
    
    var isPerformingModalReqest = false
    var authenticationAnchor: ASPresentationAnchor?
    
    var continuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialRegistration, Error>?
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        authenticationAnchor!
    }
    
    func registerWith(userId: String, widgetSessionId: String, host: String, challenge: Data, anchor: ASPresentationAnchor) async throws -> ASAuthorizationPlatformPublicKeyCredentialRegistration {
        guard continuation == nil else { throw WebAuthenticationManagerError.alreadyRegistering }
        
        authenticationAnchor = anchor
        
        let publicKeyCredentialProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: host)
        
        guard let userIdData = userId.data(using: .utf8) else {
            throw WebAuthenticationManagerError.invalidUserId
        }
        
        let registrationRequest = publicKeyCredentialProvider.createCredentialRegistrationRequest(challenge: challenge,
                                                                                                  name: widgetSessionId,
                                                                                                  userID: userIdData)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ASAuthorizationPlatformPublicKeyCredentialRegistration, Error>) in
            self.continuation = continuation
            let authController = ASAuthorizationController(authorizationRequests: [registrationRequest])
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let continuation else {
            print("Unexpected callback without continuation")
            return
        }
        
        defer {
            self.continuation = nil
        }
        
        switch authorization.credential {
        case let credentialRegistration as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            print("Successful registration")
            continuation.resume(returning: credentialRegistration)
        default:
            print("Unexpected authentication credential type: \(authorization.credential)")
            continuation.resume(throwing: WebAuthenticationManagerError.invalidAuthorizationType)
        }
        
        isPerformingModalReqest = false
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard let continuation else {
            print("Unexpected callback without continuation")
            return
        }
        
        defer {
            self.continuation = nil
        }
        
        guard let authorizationError = error as? ASAuthorizationError else {
            isPerformingModalReqest = false
            print("Unexpected error while authenticating: \(error.localizedDescription)")
            continuation.resume(throwing: error)
            return
        }
        
        if authorizationError.code == .canceled {
            print("Authentication was canceled. \(error.localizedDescription)")
            continuation.resume(throwing: WebAuthenticationManagerError.canceled)
        } else {
            print("Unexpected authentication error. \(error.localizedDescription)")
            continuation.resume(throwing: authorizationError)
        }
        
        isPerformingModalReqest = false
    }
}
