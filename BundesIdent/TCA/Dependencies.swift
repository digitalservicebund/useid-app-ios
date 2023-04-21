import Dependencies
import Analytics
import UIKit
import OSLog

enum LoggerKey: DependencyKey {
    static var liveValue: Logger = .init()
    static let previewValue: Logger = .init(category: "preview")
    static let testValue: Logger = .init()
}

#if PREVIEW
enum PreviewIDInteractionManagerKey: DependencyKey {
#if !targetEnvironment(simulator)
    static var liveValue: PreviewIDInteractionManagerType = PreviewIDInteractionManager(realIDInteractionManager: IDInteractionManager(),
                                                                                        debugIDInteractionManager: DebugIDInteractionManager())
#else
    static var liveValue: PreviewIDInteractionManagerType = PreviewIDInteractionManager(realIDInteractionManager: MockIDInteractionManager(),
                                                                                        debugIDInteractionManager: DebugIDInteractionManager())
#endif
}

extension DependencyValues {
    var previewIDInteractionManager: PreviewIDInteractionManagerType {
        get { self[PreviewIDInteractionManagerKey.self] }
        set { self[PreviewIDInteractionManagerKey.self] = newValue }
    }
}
#endif

enum IDInteractionManagerKey: DependencyKey {
#if PREVIEW
#if !targetEnvironment(simulator) // Preview on device
    static var liveValue: IDInteractionManagerType = PreviewIDInteractionManager(realIDInteractionManager: IDInteractionManager(),
                                                                                 debugIDInteractionManager: DebugIDInteractionManager())
#else // Preview in simulator
    static var liveValue: IDInteractionManagerType = PreviewIDInteractionManager(realIDInteractionManager: MockIDInteractionManager(),
                                                                                 debugIDInteractionManager: DebugIDInteractionManager())
#endif
#elseif !targetEnvironment(simulator) // Production on device
    static var liveValue: IDInteractionManagerType = IDInteractionManager()
#else // Production in simulator
    static var liveValue: IDInteractionManagerType = MockIDInteractionManager()
#endif
    static var previewValue: IDInteractionManagerType = MockIDInteractionManager()
}

enum URLOpenerKey: DependencyKey {
    static var liveValue: (URL) -> Void = { UIApplication.shared.open($0) }
    static var previewValue: (URL) -> Void = { _ in }
}

enum StorageManagerKey: DependencyKey {
    static var liveValue: StorageManagerType = StorageManager()
}

enum IssueTrackerKey: DependencyKey {
    static var liveValue: IssueTracker = SentryIssueTracker()
    static var testValue: IssueTracker = LogIssueTracker()
}

enum AnalyticsKey: DependencyKey {
    static var liveValue: AnalyticsClient = LogAnalyticsClient()
    static var testValue: AnalyticsClient = LogAnalyticsClient()
}

enum ABTesterKey: DependencyKey {
    static var liveValue: ABTester = AlwaysControlABTester()
    static var testValue: ABTester = AlwaysControlABTester()
}

enum AppVersionProviderKey: DependencyKey {
    static var liveValue: AppVersionProvider = Bundle.main
}

extension DependencyValues {
    var idInteractionManager: IDInteractionManagerType {
        get { self[IDInteractionManagerKey.self] }
        set { self[IDInteractionManagerKey.self] = newValue }
    }
    
    var storageManager: StorageManagerType {
        get { self[StorageManagerKey.self] }
        set { self[StorageManagerKey.self] = newValue }
    }
    
    var logger: Logger {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
    
    var urlOpener: (URL) -> Void {
        get { self[URLOpenerKey.self] }
        set { self[URLOpenerKey.self] = newValue }
    }
    
    var issueTracker: IssueTracker {
        get { self[IssueTrackerKey.self] }
        set { self[IssueTrackerKey.self] = newValue }
    }
    
    var analytics: AnalyticsClient {
        get { self[AnalyticsKey.self] }
        set { self[AnalyticsKey.self] = newValue }
    }

    var abTester: ABTester {
        get { self[ABTesterKey.self] }
        set { self[ABTesterKey.self] = newValue }
    }

    var appVersionProvider: AppVersionProvider {
        get { self[AppVersionProviderKey.self] }
        set { self[AppVersionProviderKey.self] = newValue }
    }
}
