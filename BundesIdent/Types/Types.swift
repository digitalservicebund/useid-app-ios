// This file is used for mock generation via Cuckoo

import Foundation
import OpenEcard
import Combine
import Sentry

typealias NFCConfigType = NSObjectProtocol & NFCConfigProtocol

protocol IDInteractionManagerType {
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher
}

protocol OpenEcardType: OpenEcardProtocol {
    func context(_ nfcConfig: (NSObjectProtocol & NFCConfigProtocol)!) -> (NSObjectProtocol & ContextManagerProtocol)!
    func context(_ defaultNFCDialgoMsg: String!, withDefaultNFCCardRecognizedMessage: String!) -> (NSObjectProtocol & ContextManagerProtocol)!
    func prepareTCTokenURL(_ tcTokenURL: String!) -> String!
    func setDebugLogLevel()
    func developerOptions() -> (NSObjectProtocol & DeveloperOptionsProtocol)!
}

protocol ContextManagerType: ContextManagerProtocol {
    func initializeContext(_ handler: NSObjectProtocol & StartServiceHandlerProtocol)
    func terminateContext(_ handler: (NSObjectProtocol & StopServiceHandlerProtocol)!)
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
protocol PreviewIDInteractionManagerType: IDInteractionManagerType, AnyObject {
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
