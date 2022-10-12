import Foundation
import CombineSchedulers
import Combine
import Analytics

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let uuidFactory: () -> UUID
    let idInteractionManager: IDInteractionManagerType
    let storageManager: StorageManagerType
    let analytics: AnalyticsClient
    let urlOpener: (URL) -> Void
    let issueTracker: IssueTracker
    
#if PREVIEW
    let debugIDInteractionManager: DebugIDInteractionManager
    
    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuidFactory: UUID.init,
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler()),
        storageManager: StorageManager(),
        analytics: MatomoAnalyticsClient(siteId: "1", baseURL: URL(string: "https://localhost/matomo.php")!),
        urlOpener: { _ in },
        issueTracker: SentryIssueTracker(),
        debugIDInteractionManager: DebugIDInteractionManager()
    )
#else
    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuidFactory: UUID.init,
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler()),
        storageManager: StorageManager(),
        analytics: MatomoAnalyticsClient(siteId: "1", baseURL: URL(string: "https://localhost/matomo.php")!),
        urlOpener: { _ in },
        issueTracker: SentryIssueTracker()
    )
#endif
}
