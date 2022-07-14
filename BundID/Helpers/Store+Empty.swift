import Foundation
import ComposableArchitecture

#if PREVIEW
extension Store where State == Void {
    static var empty: Store {
        Store<State, Action>.init(initialState: (), reducer: .empty, environment: AppEnvironment.preview)
    }
}
#endif
