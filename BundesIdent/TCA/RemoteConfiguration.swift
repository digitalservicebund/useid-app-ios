import ComposableArchitecture

struct RemoteConfiguration: ReducerProtocol {

    @Dependency(\.mainQueue) var mainQueue

    enum State: Equatable {
        case initial
        case loading
        case loaded
        case timeouted
    }

    enum Action: Equatable {
        case onAppStart
        case loadingSuccess
        case loadingError
        case timeout
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        struct TimerID: Hashable {}
        switch action {
        case .onAppStart:
            // TODO: start abtester
            state = .loading
            return EffectTask.timer(id: TimerID(), every: 1.5, on: mainQueue)
                .map { _ in .timeout }
        case .loadingSuccess where state == .timeouted:
            // TODO: track how long took the request
            return .none
        case .loadingSuccess:
            state = .loaded
            return .none
        case .loadingError:
            // TODO: track error
            state = .loaded
            return .none
        case .timeout:
            state = .timeouted
            return .cancel(id: TimerID())
        }
    }
}
