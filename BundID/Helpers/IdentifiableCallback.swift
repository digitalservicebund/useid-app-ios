import Foundation

struct IdentifiableCallback<Parameter>: Identifiable, Equatable {
    
    let id: UUID
    private let callback: (Parameter) -> Void
    
    init(id: UUID, callback: @escaping (Parameter) -> Void) {
        self.id = id
        self.callback = callback
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
    
    func callAsFunction(_ value: Parameter) {
        callback(value)
    }
}
