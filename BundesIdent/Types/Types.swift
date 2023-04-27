// This file is used for mock generation via Cuckoo

import Foundation
import Combine
import Sentry


protocol EIDInteractionManagerType {
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher

    func setPIN(_ pin: String)
    func setNewPIN(_ pin: String)
    func setCAN(_ can: String)
    func retrieveCertificateDescription()
    func acceptAccessRights()
    func interrupt()
}

protocol StorageManagerType: AnyObject {
    var setupCompleted: Bool { get set }
    var identifiedOnce: Bool { get set }
}

protocol IssueTracker {
    func addBreadcrumb(crumb: Breadcrumb)
    func capture(error: CustomNSError)
}

protocol ABTester {
    func prepare() async
    func disable()
    func isVariationActivated(for test: ABTest?) -> Bool
}

protocol AppVersionProvider {
    var version: String { get }
    var buildNumber: Int { get }
}

protocol UnleashClientWrapper: AnyObject {
    var context: [String: String] { get set }
    func start() async throws
    func variantName(forTestName testName: String) -> String?
}

#if PREVIEW
protocol PreviewEIDInteractionManagerType: EIDInteractionManagerType, AnyObject {
    var isDebugModeEnabled: Bool { get set }
    var publishedIsDebugModeEnabled: AnyPublisher<Bool, Never> { get }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher
    func debuggableChangePIN() -> DebuggableInteraction<ChangePINDebugSequence>
    func debuggableIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence>
    func debuggableCANIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence>
    func runChangePIN(debugSequence: ChangePINDebugSequence) -> [ChangePINDebugSequence]
    func runIdentify(debugSequence: IdentifyDebugSequence) -> [IdentifyDebugSequence]
}
#endif
