import Foundation
import CombineSchedulers
import Combine

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let uuidFactory: () -> UUID
    let idInteractionManager: IDInteractionManagerType
    let storageManager: StorageManagerType
    
#if PREVIEW
    let debugIDInteractionManager: DebugIDInteractionManager
    
    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuidFactory: UUID.init,
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler()),
        storageManager: StorageManager(),
        debugIDInteractionManager: DebugIDInteractionManager()
    )
#else
    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuidFactory: UUID.init,
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler()),
        storageManager: StorageManager()
    )
#endif
}
