import Combine
import Foundation
import OpenEcard

#if PREVIEW

class PreviewIDInteractionManager: PreviewIDInteractionManagerType {
    
    private let realIDInteractionManager: IDInteractionManagerType
    private let debugIDInteractionManager: DebugIDInteractionManager
    
    @Published public var isDebugModeEnabled: Bool
    var publishedIsDebugModeEnabled: AnyPublisher<Bool, Never> { $isDebugModeEnabled.eraseToAnyPublisher() }
    
    init(realIDInteractionManager: IDInteractionManagerType, debugIDInteractionManager: DebugIDInteractionManager) {
        self.realIDInteractionManager = realIDInteractionManager
        self.debugIDInteractionManager = debugIDInteractionManager
        
#if targetEnvironment(simulator)
        // Always mock except in unit tests
        isDebugModeEnabled = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
#else
        isDebugModeEnabled = false
#endif
    }
    
    func identify(tokenURL: URL, messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        precondition(!isDebugModeEnabled)
        return realIDInteractionManager.identify(tokenURL: tokenURL, messages: messages)
    }
    
    func changePIN(messages: ScanOverlayMessages) -> EIDInteractionPublisher {
        precondition(!isDebugModeEnabled)
        return realIDInteractionManager.changePIN(messages: messages)
    }
    
    func debuggableChangePIN() -> DebuggableInteraction<ChangePINDebugSequence> {
        precondition(isDebugModeEnabled)
        return debugIDInteractionManager.debuggableChangePIN()
    }
    
    func debuggableIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        precondition(isDebugModeEnabled)
        return debugIDInteractionManager.debuggableIdentify(tokenURL: tokenURL)
    }
    
    func debuggableCANIdentify(tokenURL: URL) -> DebuggableInteraction<IdentifyDebugSequence> {
        precondition(isDebugModeEnabled)
        return debugIDInteractionManager.debuggableCANIdentify(tokenURL: tokenURL)
    }
    
    func runChangePIN(debugSequence: ChangePINDebugSequence) -> [ChangePINDebugSequence] {
        precondition(isDebugModeEnabled)
        return debugIDInteractionManager.runChangePIN(debugSequence: debugSequence)
    }
    
    func runIdentify(debugSequence: IdentifyDebugSequence) -> [IdentifyDebugSequence] {
        precondition(isDebugModeEnabled)
        return debugIDInteractionManager.runIdentify(debugSequence: debugSequence)
    }
}

#endif
