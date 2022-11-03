import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPINConfirmState: Equatable {
    var enteredPIN1: String
    @BindableState var enteredPIN2 = ""
    @BindableState var alert: AlertState<SetupPersonalPINConfirmAction>?
    
    var doneButtonEnabled: Bool {
        enteredPIN1.count == 6 && enteredPIN2 == enteredPIN1
    }
    
    mutating func handlePINChange(_ enteredPIN2: String, environment: AppEnvironment) -> Effect<SetupPersonalPINConfirmAction, Never> {
        guard enteredPIN2.count == 6 else { return .none }
        guard enteredPIN1 == enteredPIN2 else {
            return .concatenate(
                .trackEvent(category: "firstTimeUser",
                            action: "errorShown",
                            name: "personalPINMismatch",
                            analytics: environment.analytics),
                Effect(value: .mismatchError))
        }
        
        return .none
    }
}

enum SetupPersonalPINConfirmAction: BindableAction, Equatable {
    case done(pin: String)
    case mismatchError
    case confirmMismatch
    case dismissAlert
    case binding(BindingAction<SetupPersonalPINConfirmState>)
}

let setupPersonalPINConfirmReducer = Reducer<SetupPersonalPINConfirmState, SetupPersonalPINConfirmAction, AppEnvironment> { state, action, environment in
    switch action {
    case .binding(\.$enteredPIN2):
        return state.handlePINChange(state.enteredPIN2, environment: environment)
    case .mismatchError:
        state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title),
                                 message: nil,
                                 buttons: [.default(TextState(L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.retry), action: .send(.confirmMismatch))])
        return .none
    default:
        return .none
    }
}.binding()
