import Foundation
import OpenEcard

class StopServiceHandler: NSObject, StopServiceHandlerProtocol {
    func onSuccess() {
        print("Service stopped successfully.")
    }
    
    func onFailure(_ response: (NSObjectProtocol & ServiceErrorResponseProtocol)!) {
        print("Failed to stop service.")
    }
}
