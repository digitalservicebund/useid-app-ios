import Dependencies
import Analytics
import UIKit
import OpenEcard
import OSLog

enum LoggerKey: DependencyKey {
    static var liveValue: Logger = Logger()
    static let previewValue: Logger = Logger(category: "preview")
    static let testValue: Logger = Logger()
}

#if PREVIEW
enum DebugInteractionManagerKey: DependencyKey {
    static var liveValue: DebugIDInteractionManager = DebugIDInteractionManager()
}

extension DependencyValues {
    var debugIDInteractionManager: DebugIDInteractionManager {
        get { self[DebugInteractionManagerKey.self] }
        set { self[DebugInteractionManagerKey.self] = newValue }
    }
}
#endif

enum IDInteractionManagerKey: DependencyKey {
#if PREVIEW
    static var liveValue: IDInteractionManagerType = MOCK_OPENECARD ? DebugIDInteractionManager() : IDInteractionManager(issueTracker: SentryIssueTracker())
#else
    static var liveValue: IDInteractionManagerType = IDInteractionManager(issueTracker: SentryIssueTracker())
#endif
    static var previewValue: IDInteractionManagerType = MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler())
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
}

enum AnalyticsKey: DependencyKey {
    static var liveValue: AnalyticsClient = LogAnalyticsClient()
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
}
