import Foundation
import OpenEcard
import OSLog

class StopServiceHandler: NSObject, StopServiceHandlerProtocol {
    let logger: Logger
    let issueTracker: IssueTracker
    
    init(issueTracker: IssueTracker) {
        logger = Logger(category: String(describing: Self.self))
        self.issueTracker = issueTracker
    }
    
    func onSuccess() {
        logger.info("Service stopped successfully.")
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        issueTracker.capture(error: ServiceErrorResponseError(code: response.getStatusCode()))
        logger.error("Failed to stop service. Reason: \(response.errorDescription)")
    }
}

struct ServiceErrorResponseError: CustomNSError {
    let code: ServiceErrorCode
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: "code: \(code.rawValue)"]
    }
}
