import Foundation
import ComposableArchitecture

struct RemoteConfiguration: ReducerProtocol {

    @Dependency(\.mainQueue) var mainQueue

    enum State: Equatable {
        case initial
        case loading(start: Date)
        case loaded
        case timeouted(start: Date)
    }

    enum Action: Equatable {
        case onAppStart
        case loadingSuccess
        case loadingError
        case timeout
        case done
        case doneAfterTimeout(start: Date)
    }

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            struct TimerID: Hashable {}
            switch (action, state) {
            case (.onAppStart, _):
                // TODO: start abtester
                state = .loading(start: Date())
                return EffectTask.timer(id: TimerID(), every: 1.5, on: mainQueue)
                    .map { _ in .timeout }
            case (.loadingSuccess, let .timeouted(start: date)), (.loadingError, let .timeouted(start: date)):
                return Effect(value: .doneAfterTimeout(start: date))
            case (.loadingSuccess, _), (.loadingError, _):
                state = .loaded
                return Effect(value: .done)
            case (.timeout, let .loading(start: date)):
                state = .timeouted(start: date)
                return .concatenate(.cancel(id: TimerID()), Effect(value: .done))
            default:
                return .none
            }
        }
        Reduce(tracking)
    }


    func tracking(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case let .doneAfterTimeout(start: date):
            return .fireAndForget {
                print("👆 doneAfterTimeout.", "Request took:", Date().timeIntervalSince(date), " seconds")
                // TODO: track how long the request took
            }
        case .loadingError:
            return .fireAndForget {
                print("👆 loadingError")
                // TODO: track error from Unleash
            }
        default:
            return .none
        }
    }
}
