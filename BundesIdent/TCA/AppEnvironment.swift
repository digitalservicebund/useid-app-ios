import Foundation
import CombineSchedulers
import Combine
import Analytics
import UIKit
import OpenEcard
import OSLog

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let uuidFactory: () -> UUID
    let idInteractionManager: IDInteractionManagerType
    let storageManager: StorageManagerType
    let analytics: AnalyticsClient
    let urlOpener: (URL) -> Void
    let issueTracker: IssueTracker
    let logger: Logger
    
#if PREVIEW
    let debugIDInteractionManager: DebugIDInteractionManager
    
    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuidFactory: UUID.init,
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler()),
        storageManager: StorageManager(),
        analytics: LogAnalyticsClient(),
        urlOpener: { _ in },
        issueTracker: SentryIssueTracker(),
        logger: Logger(category: "preview"),
        debugIDInteractionManager: DebugIDInteractionManager()
    )
#else
    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuidFactory: UUID.init,
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler()),
        storageManager: StorageManager(),
        analytics: LogAnalyticsClient(),
        urlOpener: { _ in },
        issueTracker: SentryIssueTracker(),
        logger: Logger(category: "preview")
    )
#endif
    
    static func live(appConfig: AppConfigType) -> AppEnvironment {
        let userDefaults = UserDefaults.standard
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        let storageManager = StorageManager(userDefaults: userDefaults)
        let environment: AppEnvironment
        let analytics: AnalyticsClient
        let logger = Logger()
        let issueTracker = SentryIssueTracker()
        
#if DEBUG
        analytics = LogAnalyticsClient()
#else
        analytics = MatomoAnalyticsClient(siteId: appConfig.matomoSiteID, baseURL: appConfig.matomoURL)
#endif
        
#if PREVIEW
        if MOCK_OPENECARD {
            let idInteractionManager = DebugIDInteractionManager()
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                storageManager: storageManager,
                analytics: analytics,
                urlOpener: { UIApplication.shared.open($0) },
                issueTracker: issueTracker,
                logger: logger,
                debugIDInteractionManager: idInteractionManager
            )
        } else {
            let idInteractionManager = IDInteractionManager(issueTracker: issueTracker)
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                storageManager: storageManager,
                analytics: analytics,
                urlOpener: { UIApplication.shared.open($0) },
                issueTracker: issueTracker,
                logger: logger,
                debugIDInteractionManager: DebugIDInteractionManager()
            )
        }
#else
        let idInteractionManager = IDInteractionManager(issueTracker: issueTracker)
        
        environment = AppEnvironment(
            mainQueue: mainQueue,
            uuidFactory: UUID.init,
            idInteractionManager: idInteractionManager,
            storageManager: storageManager,
            analytics: analytics,
            urlOpener: { UIApplication.shared.open($0) },
            issueTracker: issueTracker,
            logger: logger
        )
#endif
        return environment
    }
}
