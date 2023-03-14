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
        case abTesterConfigured
        case timeout
        case done
    }

    private struct TimerID: Hashable {}

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .start:
            let prepareABTester = EffectTask.run { send in
                await abTester.prepare()
                await send(Action.abTesterConfigured)
            }
            let startTimer = EffectTask.timer(id: TimerID(), every: .seconds(state.timeoutInterval), on: mainQueue)
                .map { _ in Action.timeout }
            return .merge(prepareABTester, startTimer)
        case .abTesterConfigured where state.finished == false:
            state.abTesterConfigured = true
            return cancelTimerAndFinish(state: &state)
        case .timeout where state.abTesterConfigured == false:
            abTester.disable()
            return cancelTimerAndFinish(state: &state)
        default:
            return .none
        }
    }

    private func cancelTimerAndFinish(state: inout State) -> EffectTask<Action> {
        state.finished = true
        return .concatenate(.cancel(id: TimerID()), EffectTask(value: .done))
    }
}
