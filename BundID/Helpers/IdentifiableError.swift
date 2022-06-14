import Foundation

struct IdentifiableError: Error, LocalizedError, Identifiable, Equatable {
    
    let id: UUID
    let error: Error
    
    init(_ error: Error) {
        if let identifiableError = error as? IdentifiableError {
            self.id = identifiableError.id
            self.error = identifiableError.error
        } else {
            self.id = UUID()
            self.error = error
        }
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    var errorDescription: String? {
        return (error as NSError).localizedDescription
    }
}
