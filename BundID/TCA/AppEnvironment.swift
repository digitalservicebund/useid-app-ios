import Foundation
import CombineSchedulers
import Combine

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let uuidFactory: () -> UUID
    let idInteractionManager: IDInteractionManagerType
    
    #if PREVIEW
    let debugIDInteractionManager: DebugIDInteractionManager
    #endif
    
    #if DEBUG
    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        uuidFactory: UUID.init,
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler()),
        debugIDInteractionManager: DebugIDInteractionManager())
    #endif
}
