import Foundation
import CombineSchedulers
import Combine

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    let idInteractionManager: IDInteractionManagerType

    static let preview: AppEnvironment = AppEnvironment(
        mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
        idInteractionManager: MockIDInteractionManager(queue: DispatchQueue.main.eraseToAnyScheduler())
    )
}
