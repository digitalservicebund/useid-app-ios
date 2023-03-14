import Foundation
import ComposableArchitecture

struct RemoteConfiguration: ReducerProtocol {

    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.abTester) var abTester

    struct State: Equatable {
        let timeoutInterval: TimeInterval = 1.5
        var abTesterConfigured: Bool = false
        var finished: Bool = false
    }

    enum Action: Equatable {
        case start
        case prepareABTester
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
            return .concatenate(EffectTask(value: .prepareABTester), EffectTask(value: .startTimeoutTimer))
        case .prepareABTester:
            return .run { send in
                await abTester.prepare()
                await send(.abTesterConfigured)
            }
        case .startTimeoutTimer:
            return EffectTask.timer(id: TimerID(), every: .seconds(state.timeoutInterval), on: mainQueue).map { _ in .timeout }
        case .stopTimoutTimer:
            return .concatenate(.cancel(id: TimerID()), EffectTask(value: .done))
        case .abTesterConfigured:
            state.abTesterConfigured = true
            return EffectTask(value: .stopTimoutTimer)
        case .timeout where state.abTesterConfigured == false:
            abTester.disable()
            return EffectTask(value: .stopTimoutTimer)
        default:
            state.finished = true
            return .none
        }
    }
}
