import Foundation
import ComposableArchitecture

struct RemoteConfiguration: ReducerProtocol {

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.abTester) var abTester

    struct State: Equatable {
        let timeoutInterval: TimeInterval = 1.5
        var abTesterConfigured: Bool = false
    }

    enum Action: Equatable {
        case start
        case abTesterConfigured
        case timeout
        case startTimeoutTimer
        case stopTimoutTimer
        case done
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        struct TimerID: Hashable {}
        switch action {
        case .start:
            abTester.prepare() // TODO: wait for response and send `abTesterConfigured`
            return Effect(value: .startTimeoutTimer)
        case .startTimeoutTimer:
            return EffectTask.timer(id: TimerID(), every: .seconds(state.timeoutInterval), on: mainQueue).map { _ in .timeout }
        case .stopTimoutTimer:
            return .concatenate(.cancel(id: TimerID()), Effect(value: .done))
        case .abTesterConfigured:
            state.abTesterConfigured = true
            return Effect(value: .stopTimoutTimer)
        case .timeout where state.abTesterConfigured == false:
            abTester.disable()
            return Effect(value: .stopTimoutTimer)
        default:
            return .none
        }
    }
}
