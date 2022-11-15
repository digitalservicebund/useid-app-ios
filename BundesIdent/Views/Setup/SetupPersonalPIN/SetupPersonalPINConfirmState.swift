import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPINConfirmState: Equatable {
    var enteredPIN1: String
    @BindableState var enteredPIN2 = ""
    @BindableState var alert: AlertState<SetupPersonalPINConfirmAction>?
    
    var doneButtonEnabled: Bool {
        enteredPIN2.count == 6
    }
}

enum SetupPersonalPINConfirmAction: BindableAction, Equatable {
    case done(pin: String)
    case mismatchError
    case confirmMismatch
    case dismissAlert
    case checkPINs
    case binding(BindingAction<SetupPersonalPINConfirmState>)
}

let setupPersonalPINConfirmReducer = Reducer<SetupPersonalPINConfirmState, SetupPersonalPINConfirmAction, AppEnvironment> { state, action, environment in
    switch action {
    case .mismatchError:
        state.alert = AlertState(title: TextState(verbatim: L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.title),
                                 message: nil,
                                 buttons: [.default(TextState(L10n.FirstTimeUser.PersonalPIN.Error.Mismatch.retry), action: .send(.confirmMismatch))])
        return .none
    case .checkPINs:
        guard state.enteredPIN2.count == 6 else { return .none }
        guard state.enteredPIN1 == state.enteredPIN2 else {
            return .concatenate(
                .trackEvent(category: "firstTimeUser",
                            action: "errorShown",
                            name: "personalPINMismatch",
                            analytics: environment.analytics),
                Effect(value: .mismatchError))
        }
        return Effect(value: .done(pin: state.enteredPIN1))
    default:
        return .none
    }
}.binding()
