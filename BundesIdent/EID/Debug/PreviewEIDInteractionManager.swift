import Combine
import Foundation

#if PREVIEW

class PreviewEIDInteractionManager: PreviewEIDInteractionManagerType {
    
    private let realManager: EIDInteractionManagerType
    private let debugManager: DebugEIDInteractionManager
    
    @Published public var isDebugModeEnabled: Bool
    var publishedIsDebugModeEnabled: AnyPublisher<Bool, Never> { $isDebugModeEnabled.eraseToAnyPublisher() }
    
    init(real: EIDInteractionManagerType, debug: DebugEIDInteractionManager) {
        self.realManager = real
        self.debugManager = debug
        
#if targetEnvironment(simulator)
        // Always mock except in unit tests
        isDebugModeEnabled = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
#else
        isDebugModeEnabled = false
#endif
    }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        precondition(!isDebugModeEnabled)
        return realManager.identify(tokenURL: tokenURL, messages: messages)
    }
    
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        precondition(!isDebugModeEnabled)
        return realManager.changePIN(messages: messages)
    }
    
    func debuggableChangePIN() -> DebuggableInteraction<ChangePINDebugSequence> {
        precondition(isDebugModeEnabled)
        return debugManager.debuggableChangePIN()
    }
    
    func debuggableIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        precondition(isDebugModeEnabled)
        return debugManager.debuggableIdentify(tokenURL: tokenURL)
    }
    
    func debuggableCANIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        precondition(isDebugModeEnabled)
        return debugManager.debuggableCANIdentify(tokenURL: tokenURL)
    }
    
    func runChangePIN(debugSequence: ChangePINDebugSequence) -> [ChangePINDebugSequence] {
        precondition(isDebugModeEnabled)
        return debugManager.runChangePIN(debugSequence: debugSequence)
    }
    
    func runIdentify(debugSequence: IdentifyDebugSequence) -> [IdentifyDebugSequence] {
        precondition(isDebugModeEnabled)
        return debugManager.runIdentify(debugSequence: debugSequence)
    }

    func setPIN(_ pin: String) {
        realManager.setPIN(pin)
    }

    func setNewPIN(_ pin: String) {
        realManager.setNewPIN(pin)
    }

    func setCAN(_ can: String) {
        realManager.setCAN(can)
    }
    
    func retrieveCertificateDescription() {
        realManager.retrieveCertificateDescription()
    }

    func acceptAccessRights() {
        realManager.acceptAccessRights()
    }

    func interrupt() {
        realManager.interrupt()
    }
}

#endif
