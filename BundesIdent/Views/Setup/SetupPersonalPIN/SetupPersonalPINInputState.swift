import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPINInputState: Equatable {
    @BindableState var enteredPIN = ""
    
    var doneButtonEnabled: Bool {
        enteredPIN.count == Constants.PERSONAL_PIN_DIGIT_COUNT
    }
}

enum SetupPersonalPINInputAction: BindableAction, Equatable {
    case done(pin: String)
    case onAppear
    case binding(BindingAction<SetupPersonalPINInputState>)
}

let setupPersonalPINInputReducer = Reducer<SetupPersonalPINInputState, SetupPersonalPINInputAction, AppEnvironment> { state, action, _ in
    switch action {
    case .onAppear:
        state.enteredPIN = ""
        return .none
    default:
        return .none
    }
}.binding()
