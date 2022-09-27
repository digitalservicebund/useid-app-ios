import Foundation
import OpenEcard
import Sentry

class StopServiceHandler: NSObject, StopServiceHandlerProtocol {
    func onSuccess() {
        print("Service stopped successfully.")
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        SentrySDK.capture(error: ServiceErrorResponseError(code: response.getStatusCode()))
        print("Failed to stop service. Reason: \( response.errorDescription)")
    }
}

struct ServiceErrorResponseError: Error {
    let code: ServiceErrorCode
}
