import Foundation

struct IdentifiableError: Error, LocalizedError, Identifiable, Equatable {
    
    let id: UUID
    let error: Error
    
    init(_ error: Error) {
        if let identifiableError = error as? IdentifiableError {
            id = identifiableError.id
            self.error = identifiableError.error
        } else {
            id = UUID()
            self.error = error
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    var errorDescription: String? {
        (error as NSError).localizedDescription
    }
}
