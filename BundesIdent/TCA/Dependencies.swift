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
enum PreviewEIDInteractionManagerKey: DependencyKey {
    typealias Value = PreviewEIDInteractionManagerType
#if !targetEnvironment(simulator)
    static var liveValue: Value = PreviewEIDInteractionManager(real: EIDInteractionManager(), debug: .init())
#else
    static var liveValue: Value = PreviewEIDInteractionManager(real: UnimplementedEIDInteractionManager(), debug: .init())
#endif
}

extension DependencyValues {
    var previewEIDInteractionManager: PreviewEIDInteractionManagerType {
        get { self[PreviewEIDInteractionManagerKey.self] }
        set { self[PreviewEIDInteractionManagerKey.self] = newValue }
    }
}
#endif

enum EIDInteractionManagerKey: DependencyKey {
#if PREVIEW
    static var liveValue: EIDInteractionManagerType = PreviewEIDInteractionManagerKey.liveValue
#elseif !targetEnvironment(simulator)
    static var liveValue: EIDInteractionManagerType = EIDInteractionManager()
#else
    static var liveValue: EIDInteractionManagerType = UnimplementedEIDInteractionManager()
#endif
    static var previewValue: EIDInteractionManagerType = UnimplementedEIDInteractionManager()
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
    var eIDInteractionManager: EIDInteractionManagerType {
        get { self[EIDInteractionManagerKey.self] }
        set { self[EIDInteractionManagerKey.self] = newValue }
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
