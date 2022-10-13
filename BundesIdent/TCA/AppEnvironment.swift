import Foundation
import CombineSchedulers
import Combine
import Analytics
import UIKit
import OpenEcard

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
        analytics: LogAnalyticsClient(),
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
        analytics: LogAnalyticsClient(),
        urlOpener: { _ in },
        issueTracker: SentryIssueTracker()
    )
#endif
    
    static func live(appConfig: AppConfigType) -> AppEnvironment {
        let userDefaults = UserDefaults.standard
        let mainQueue = DispatchQueue.main.eraseToAnyScheduler()
        let storageManager = StorageManager(userDefaults: userDefaults)
        let environment: AppEnvironment
        let analytics: AnalyticsClient
        
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
                issueTracker: SentryIssueTracker(),
                debugIDInteractionManager: idInteractionManager
            )
        } else {
            let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
            
            environment = AppEnvironment(
                mainQueue: mainQueue,
                uuidFactory: UUID.init,
                idInteractionManager: idInteractionManager,
                storageManager: storageManager,
                analytics: analytics,
                urlOpener: { UIApplication.shared.open($0) },
                issueTracker: SentryIssueTracker(),
                debugIDInteractionManager: DebugIDInteractionManager()
            )
        }
#else
        let idInteractionManager = IDInteractionManager(openEcard: OpenEcardImp())
        
        environment = AppEnvironment(
            mainQueue: mainQueue,
            uuidFactory: UUID.init,
            idInteractionManager: idInteractionManager,
            storageManager: storageManager,
            analytics: analytics,
            urlOpener: { UIApplication.shared.open($0) },
            issueTracker: SentryIssueTracker()
        )
#endif
        return environment
    }
}
