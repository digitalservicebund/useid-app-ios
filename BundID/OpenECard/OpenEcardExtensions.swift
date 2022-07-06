import Foundation
import OpenEcard
import Combine

typealias EIDInteractionPublisher = AnyPublisher<EIDInteractionEvent, IDCardInteractionError>
typealias FlaggedAttributes = [IDCardAttribute: Bool]

extension ServiceErrorResponseProtocol {
    var errorDescription: String {
        "\(getStatusCode()): \(getErrorMessage() ?? "n/a")"
    }
}

extension Array where Element == NSObjectProtocol & SelectableItemProtocol {
    func mapToAttributeRequirements() throws -> FlaggedAttributes {
        let keyValuePairs: [(IDCardAttribute, Bool)] = try map { item in
            guard let attribute = IDCardAttribute(rawValue: item.getName()) else {
                throw IDCardInteractionError.unexpectedReadAttribute(item.getName())
            }
            return (attribute, item.isRequired())
        }
        return FlaggedAttributes(uniqueKeysWithValues: keyValuePairs)
    }
}

class SelectableItem: NSObject, SelectableItemProtocol {
    private let attribute: String
    private let checked: Bool
    
    init(attribute: String, checked: Bool) {
        self.attribute = attribute
        self.checked = checked
    }
    
    func getName() -> String! { attribute }
    func getText() -> String! { "" }
    func isChecked() -> Bool { checked }
    func setChecked(_ checked: Bool) { }
    func isRequired() -> Bool { false }
}

// Does not work probably due to robovm bug

// extension Dictionary where Key == IDCardAttribute, Value == Bool {
//     var selectableItemsSettingChecked: [NSObjectProtocol & SelectableItemProtocol] {
//         map { SelectableItem(attribute: $0.key.rawValue, checked: $0.value) }
//     }
// }
