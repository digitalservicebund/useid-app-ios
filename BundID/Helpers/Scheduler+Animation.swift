import Foundation
import SwiftUI
import Combine
import CombineSchedulers

extension Scheduler {
    func animation(_ animation: Animation? = .default) -> AnySchedulerOf<Self> {
        .init(
            minimumTolerance: { self.minimumTolerance },
            now: { self.now },
            scheduleImmediately: { options, action in
                self.schedule(options: options) {
                    withAnimation(animation, action)
                }
            },
            delayed: { after, tolerance, options, action in
                self.schedule(after: after, tolerance: tolerance, options: options) {
                    withAnimation(animation, action)
                }
            },
            interval: { after, interval, tolerance, options, action in
                self.schedule(after: after, interval: interval, tolerance: tolerance, options: options) {
                    withAnimation(animation, action)
                }
            }
        )
    }
}
