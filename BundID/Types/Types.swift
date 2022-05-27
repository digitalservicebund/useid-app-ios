import Foundation

protocol IDInteractionManagerType {
    func identify(tokenURL: String) -> EIDInteractionPublisher
    func changePIN() -> EIDInteractionPublisher
}
