import Foundation
import CombineSchedulers
import Analytics

@testable import BundID

extension AppEnvironment {
    static func mocked(mainQueue: AnySchedulerOf<DispatchQueue>? = nil,
                       uuidFactory: (() -> UUID)? = nil,
                       idInteractionManager: IDInteractionManagerType? = nil,
                       storageManager: StorageManagerType? = nil,
                       analytics: AnalyticsClient? = nil,
                       debugIDInteractionManager: DebugIDInteractionManager? = nil,
                       urlOpener: @escaping (URL) -> Void = { _ in }) -> AppEnvironment {
        let queue = mainQueue ?? DispatchQueue.test.eraseToAnyScheduler()
        return AppEnvironment(mainQueue: queue,
                              uuidFactory: uuidFactory ?? UUID.init,
                              idInteractionManager: idInteractionManager ?? MockIDInteractionManager(queue: queue),
                              storageManager: storageManager ?? StorageManager(),
                              analytics: analytics ?? MockAnalyticsClient(),
                              urlOpener: urlOpener,
                              debugIDInteractionManager: debugIDInteractionManager ?? DebugIDInteractionManager())
    }
}
