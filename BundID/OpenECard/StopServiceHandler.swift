import Foundation
import OpenEcard

class StopServiceHandler: NSObject, StopServiceHandlerProtocol {
    func onSuccess() {
        print("Service stopped successfully.")
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        SentryIssueTracker().capture(error: ServiceErrorResponseError(code: response.getStatusCode()))
        print("Failed to stop service. Reason: \( response.errorDescription)")
    }
}

struct ServiceErrorResponseError: CustomNSError {
    let code: ServiceErrorCode
    
    var errorUserInfo: [String: Any] {
        [NSDebugDescriptionErrorKey: "code: \(code.rawValue)"]
    }
}
