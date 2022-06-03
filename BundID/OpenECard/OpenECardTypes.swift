import Foundation
import OpenEcard
import Combine

protocol ControllerCallbackType: NSObjectProtocol, ControllerCallbackProtocol {
    var publisher: EIDInteractionPublisher { get }
}

protocol EACInteractionType: NSObjectProtocol, EacInteractionProtocol {
    var publisher: EIDInteractionPublisher { get }
}

protocol PINManagementInteractionType: NSObjectProtocol, PinManagementInteractionProtocol {
    var publisher: EIDInteractionPublisher { get }
}
