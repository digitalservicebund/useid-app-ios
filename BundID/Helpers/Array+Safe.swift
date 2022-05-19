import Foundation

extension Array {
    subscript(safe index: Index) -> Element? {
        if count > index {
            return self[index]
        } else {
            return nil
        }
    }
}
