import Foundation
import RealHTTP

protocol APIControllerType {
    
    func setEnvironment(_ environment: BackendEnvironment)
    
    func validateTCTokenURL(sessionId: String, tokenId: String) async throws -> Bool
    func retrieveTransactionInfo(sessionId: String) async throws -> TransactionInfo
    func sendSessionEvent(sessionId: String, redirectURL: URL) async throws
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
    
    func setEnvironment(_ environment: BackendEnvironment) {
        client.baseURL = environment.baseURL
    }
    
    func validateTCTokenURL(sessionId: String, tokenId: String) async throws -> Bool {
        let req = try HTTPRequest(method: .get, URI: "/identification/sessions/{sessionId}/tokens/{tokenId}", variables: ["sessionId": sessionId, "tokenId": tokenId])
        let response = try await req.fetch(client)
        return true
        
        // TODO: Once Simons code is merged
        switch response.statusCode {
        case .noContent: return true
        case .notFound: return false
        default:
            guard let error = response.error else { throw Error.unexpectedStatusCode(response.statusCode.rawValue) }
            throw error
        }
    }
    
    func retrieveTransactionInfo(sessionId: String) async throws -> TransactionInfo {
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
        let req = HTTPRequest(method: .post, URI: "/events/{sessionId}/success", variables: ["sessionId": sessionId]) {
            $0.body = .json(payload)
        }
        let response = try await req.fetch(client)
        
        guard response.statusCode == .accepted else {
            throw Error.unexpectedStatusCode(response.statusCode.rawValue)
        }
    }
}
