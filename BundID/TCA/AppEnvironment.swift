import Foundation
import CombineSchedulers

struct AppEnvironment {
    let mainQueue: AnySchedulerOf<DispatchQueue>
    
    static let preview: AppEnvironment = AppEnvironment(mainQueue: DispatchQueue.main.eraseToAnyScheduler())
}
