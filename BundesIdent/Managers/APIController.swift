import AuthenticationServices
import Foundation
import RealHTTP

struct UserRegistrationResponse: Codable, Equatable {
    let credentialId: String
    let pkcCreationOptions: PkcCreationOptions
}

struct PkcUser: Codable, Equatable {
    var name: String
    var displayName: String
    var id: Data
    
    public init(from decoder: Decoder) throws {
        enum RootKeys: String, CodingKey { case name; case displayName; case id }
        let container = try decoder.container(keyedBy: RootKeys.self)
        
        guard let idData = Data(base64urlEncoded: try container.decode(String.self, forKey: .id)) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [RootKeys.id], debugDescription: "user id not correctly formatted"))
        }
        id = idData
        name = try container.decode(String.self, forKey: .name)
        displayName = try container.decode(String.self, forKey: .displayName)
    }
}

struct PkcCreationOptions: Codable, Equatable {
    var user: PkcUser
    var challenge: Data
    
    public init(from decoder: Decoder) throws {
        enum RootKeys: String, CodingKey { case publicKey }
        let container = try decoder.container(keyedBy: RootKeys.self)
        enum PublicKeyKeys: String, CodingKey { case user; case challenge }
        let publicKey = try container.nestedContainer(keyedBy: PublicKeyKeys.self, forKey: .publicKey)
        
        guard let challengeData = Data(base64urlEncoded: try publicKey.decode(String.self, forKey: .challenge)) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [RootKeys.publicKey, PublicKeyKeys.challenge], debugDescription: "challenge not correctly formatted"))
        }
        challenge = challengeData
        user = try publicKey.decode(PkcUser.self, forKey: .user)
    }
}

struct GeneratedRegistrationCredentials: Codable, Equatable {
    var attestationObject: Data
    var clientDataJSON: Data
    var id: Data
}

//struct UserAuthenticationRequest: Codable, Equatable {
//    var rawAttestationObject: Data
//    var rawClientDataJSON: Data
//    var credentialId: Data
//}
//
//struct UserAuthenticationResponse: Codable, Equatable {
//    let challenge: Data
//}
//
//struct AuthenticationDetails: Codable, Equatable {
//    var rawAuthenticatorData: Data
//    var signature: Data
//    var rawClientDataJSON: Data
//    var credentialId: Data
//}

protocol APIControllerType {
    
    var hostname: String { get }
    
    func setEnvironment(_ environment: BackendEnvironment)
    
    func validateTCTokenURL(sessionId: String, tokenId: String) async throws -> Bool
    func retrieveTransactionInfo(sessionId: String) async throws -> TransactionInfo
    func sendSessionEvent(sessionId: String, redirectURL: URL) async throws
    
    /**
     POST /credentials
     */
    func initiateRegistration(widgetSessionId: String, refreshAddress: URL) async throws -> UserRegistrationResponse
    
    /**
     PUT /credentials/:credentialId
     */
    func completeRegistration(credentialId: String, generatedRegistrationCredentials: GeneratedRegistrationCredentials) async throws
 
    //  TODO: Implement later for re-using passkeys
//    /**
//     POST /users/:userId/initiate
//     */
//    func initiateAuthentication(userId: UserId) async throws -> UserAuthenticationResponse
//
//    /**
//     POST /users/:userId/:widgetSessionId/auth/complete
//     (previously /event-streams/:widgetSessionId/success)
//     */
//    func completeAuthentication(userId: UserId, widgetSessionId: String, authenticationDetails: AuthenticationDetails, refreshURL: URL) async throws
}

enum BackendEnvironment: String, Identifiable, CaseIterable {
    
#if DEBUG || PREVIEW
    /// BaseURL: http://localhost:8080
    case local
    
    /// BaseURL: https://useid.dev.ds4g.net
    case staging
#endif
    
    /// BaseURL: https://eid.digitalservicebund.de
    case production
    
    static var `default`: BackendEnvironment {
#if DEBUG || PREVIEW
        return .staging
#else
        return .production
#endif
    }
    
    var id: String { rawValue }
    
    var baseURL: URL {
        switch self {
#if DEBUG || PREVIEW
        case .local: return URL(string: "http://localhost:8080/api/v1")!
        case .staging: return URL(string: "https://useid.dev.ds4g.net/api/v1")!
#endif
        case .production: return URL(string: "https://eid.digitalservicebund.de/api/v1")!
        }
    }
}

class APIController: APIControllerType {

    enum Error: Swift.Error {
        case tcTokenURLMalformed
        case notYetImplemented
        case invalidResponse
        case unexpectedStatusCode(Int)
    }
    
    var jsonEncoder: JSONEncoder
    var jsonDecoder: JSONDecoder
    var client: HTTPClient
    
    init(client: HTTPClient, jsonEncoder: JSONEncoder, jsonDecoder: JSONDecoder) {
        self.client = client
        self.client.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        self.jsonEncoder = jsonEncoder
        self.jsonDecoder = jsonDecoder
    }
    
    var hostname: String {
        client.baseURL!.fullHost!
    }
    
    func setEnvironment(_ environment: BackendEnvironment) {
        client.baseURL = environment.baseURL
    }
    
    func validateTCTokenURL(sessionId: String, tokenId: String) async throws -> Bool {
        let req = try HTTPRequest(method: .get, URI: "/identification/sessions/{sessionId}/tokens/{tokenId}", variables: ["sessionId": sessionId, "tokenId": tokenId])
        let response = try await req.fetch(client)
        
        switch response.statusCode {
        case .noContent: return true
        case .notFound: return false
        default:
            guard let error = response.error else { throw Error.unexpectedStatusCode(response.statusCode.rawValue) }
            throw error
        }
    }
    
    func retrieveTransactionInfo(sessionId: String) async throws -> TransactionInfo {
        return TransactionInfo.preview
        let req = try HTTPRequest(method: .get, URI: "/identification/sessions/{sessionId}/transaction-info", variables: ["sessionId": sessionId])
        let response = try await req.fetch(client)
        let transactionInfo = try response.decode(TransactionInfo.self, decoder: jsonDecoder)
        return transactionInfo
    }
    
    func sendSessionEvent(sessionId: String, redirectURL: URL) async throws {
        struct Payload: Codable {
            let refreshAddress: String
        }
        
        let payload = Payload(refreshAddress: redirectURL.absoluteString)
        let req = HTTPRequest(method: .post, URI: "/event-streams/{sessionId}/success", variables: ["sessionId": sessionId]) {
            $0.body = .json(payload)
        }
        let response = try await req.fetch(client)
        
        guard response.statusCode == .accepted else {
            throw Error.unexpectedStatusCode(response.statusCode.rawValue)
        }
    }
    
    func initiateRegistration(widgetSessionId: String, refreshAddress: URL) async throws -> UserRegistrationResponse {
        struct UserRegistrationRequest: Codable, Equatable {
            let widgetSessionId: String
            let refreshAddress: String
        }
        let userRegistrationRequest = UserRegistrationRequest(widgetSessionId: widgetSessionId, refreshAddress: refreshAddress.absoluteString)
        
        let req = try HTTPRequest(method: .post, "/credentials", body: .json(userRegistrationRequest))
        let response = try await req.fetch(client)
        
        guard response.statusCode == .created else {
            throw Error.unexpectedStatusCode(response.statusCode.rawValue)
        }
        
        struct RawUserRegistrationResponse: Codable, Equatable {
            let credentialId: String
            let pkcCreationOptions: String
        }
        
        let decodedResponse = try response.decode(RawUserRegistrationResponse.self)
        guard let pkcCreationOptionsData = decodedResponse.pkcCreationOptions.data(using: .utf8) else {
            throw Error.invalidResponse
        }
        let decodedPkcCreationOptions = try JSONDecoder().decode(PkcCreationOptions.self, from: pkcCreationOptionsData)
        return UserRegistrationResponse(credentialId: decodedResponse.credentialId, pkcCreationOptions: decodedPkcCreationOptions)
    }
    
    func completeRegistration(credentialId: String, generatedRegistrationCredentials: GeneratedRegistrationCredentials) async throws {
        struct RegistrationDetails: Codable, Equatable {
            var attestationObject: String
            var clientDataJSON: String
        }
        
        struct ClientExtensionResults: Codable, Equatable {
            struct CredProps: Codable, Equatable { var rk = true }
            var credProps = CredProps()
        }

        struct Payload: Codable, Equatable {
            var id: String
            var type: String
            var response: RegistrationDetails
            var clientExtensionResults = ClientExtensionResults()
        }
        
        let body = Payload(id: generatedRegistrationCredentials.id.base64urlEncodedString(), type: "public-key", response: RegistrationDetails(attestationObject: generatedRegistrationCredentials.attestationObject.base64urlEncodedString(), clientDataJSON: generatedRegistrationCredentials.clientDataJSON.base64urlEncodedString()))
        
        let req = HTTPRequest(method: .put, URI: "/credentials/{credentialId}",
                              variables: [
                                  "credentialId": credentialId,
                              ]) {
            $0.body = .json(body)
        }
        let response = try await req.fetch(client)
        
        guard response.statusCode == .noContent else {
            throw Error.unexpectedStatusCode(response.statusCode.rawValue)
        }
    }
}

fileprivate extension Data {
    func base64urlEncodedString() -> String {
        var result = self.base64EncodedString()
        result = result.replacingOccurrences(of: "+", with: "-")
        result = result.replacingOccurrences(of: "/", with: "_")
        result = result.replacingOccurrences(of: "=", with: "")
        return result
    }
    
    init?(base64urlEncoded input: String) {
        var base64 = input
        base64 = base64.replacingOccurrences(of: "-", with: "+")
        base64 = base64.replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64 = base64.appending("=")
        }
        self.init(base64Encoded: base64)
    }
}
