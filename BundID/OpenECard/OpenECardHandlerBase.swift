import Foundation
import Combine
import OpenEcard

class OpenECardHandlerBase: NSObject {
    let delegate: OpenECardHandlerDelegate
    
    init(delegate: OpenECardHandlerDelegate) {
        self.delegate = delegate
    }
}
