import Foundation

extension UUID {
    init(number: Int) {
        let string = String(format: "00000000-0000-0000-0000-%012d", number)
        self = UUID(uuidString: string)!
    }
}
