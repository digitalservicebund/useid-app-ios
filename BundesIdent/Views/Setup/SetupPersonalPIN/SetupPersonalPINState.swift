import SwiftUI
import Combine
import ComposableArchitecture

struct SetupPersonalPINState: Equatable {
    enum Field: String, Hashable {
        case pin1
        case pin2
    }
    
    enum SetupPersonalPINError: Hashable {
        case mismatch
    }
    
    @BindableState var enteredPIN1 = ""
    @BindableState var enteredPIN2 = ""
    var showPIN2 = false
    @BindableState var focusedField: Field?
    var error: SetupPersonalPINError?
    var remainingAttempts = 0
    
    mutating func handlePIN1Change(_ enteredPIN1: String) -> Effect<SetupPersonalPINAction, Never> {
        if !enteredPIN1.isEmpty {
            withAnimation {
                error = nil
            }
        }

        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || !enteredPIN2.isEmpty
        }
        
        if enteredPIN1.count == 6 {
            focusedField = .pin2
        }
        
        return .none
    }
    
    mutating func handlePIN2Change(_ enteredPIN2: String, environment: AppEnvironment) -> Effect<SetupPersonalPINAction, Never> {
        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || !enteredPIN2.isEmpty
        }
        
        guard enteredPIN2.count == 6 else { return .none }
        guard enteredPIN1 == enteredPIN2 else {
            withAnimation {
                remainingAttempts += 1
            }
            return .concatenate(
                .trackEvent(category: "firstTimeUser",
                            action: "errorShown",
                            name: "personalPINMismatch",
                            analytics: environment.analytics),
                Effect(value: withAnimation { .reset })
                    .delay(for: 0.2, scheduler: environment.mainQueue.animation(.linear(duration: 0.2)))
                    .eraseToEffect()
            )
        }
        
        return Effect(value: .done(pin: enteredPIN2))
    }
}

enum SetupPersonalPINAction: BindableAction, Equatable {
    case onAppear
    case focus(SetupPersonalPINState.Field)
    case done(pin: String)
    case reset
    case binding(BindingAction<SetupPersonalPINState>)
}

let setupPersonalPINReducer = Reducer<SetupPersonalPINState, SetupPersonalPINAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        let effect = Effect<SetupPersonalPINAction, Never>(value: .focus(.pin1))
        if #available(iOS 16, *) {
            return effect
        } else {
            // On iOS 15, setting a focus state only works after a short delay
            return effect.delay(for: 0.75, scheduler: environment.mainQueue).eraseToEffect()
        }
    case .binding(\.$enteredPIN1):
        return state.handlePIN1Change(state.enteredPIN1)
    case .binding(\.$enteredPIN2):
        return state.handlePIN2Change(state.enteredPIN2, environment: environment)
    case .reset:
        state.error = .mismatch
        state.showPIN2 = false
        state.enteredPIN2 = ""
        state.enteredPIN1 = ""
        state.focusedField = .pin1
        return .none
    case .focus(let field):
        state.focusedField = field
        return .none
    default:
        return .none
    }
}.binding()
