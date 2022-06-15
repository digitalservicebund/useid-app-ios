import Foundation

enum AuthenticationTerms: Equatable, CustomStringConvertible {
    case text(String)
    
    var description: String {
        switch self {
        case .text(let description): return description
        }
    }
}
