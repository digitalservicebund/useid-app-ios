import Foundation
import CombineSchedulers

@testable import BundID

extension AppEnvironment {
    static func mocked(
        mainQueue: AnySchedulerOf<DispatchQueue> = DispatchQueue.test.eraseToAnyScheduler(),
        uuidFactory: @escaping () -> UUID = UUID.init,
        idInteractionManager: IDInteractionManagerType? = nil,
        storageManager: StorageManagerType? = nil,
        debugIDInteractionManager: DebugIDInteractionManager? = nil
    ) -> AppEnvironment {
        return AppEnvironment(mainQueue: mainQueue,
                              uuidFactory: uuidFactory,
                              idInteractionManager: idInteractionManager ?? MockIDInteractionManager(queue: mainQueue),
                              storageManager: storageManager ?? StorageManager(),
                              debugIDInteractionManager: debugIDInteractionManager ?? DebugIDInteractionManager())
    }
}
