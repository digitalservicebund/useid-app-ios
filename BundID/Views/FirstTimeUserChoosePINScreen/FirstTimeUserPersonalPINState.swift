import SwiftUI
import Combine
import ComposableArchitecture

struct FirstTimeUserPersonalPINState: Equatable {
    @BindableState var enteredPIN1: String = ""
    @BindableState var enteredPIN2: String = ""
    var showPIN2: Bool = false
    @BindableState var focusPIN1: Bool = true
    @BindableState var focusPIN2: Bool = false
    var error: FirstTimeUserPersonalPINScreenError?
    var attempts: Int = 0
    
    mutating func handlePIN1Change(_ enteredPIN1: String) -> Effect<FirstTimeUserPersonalPINAction, Never> {
        if !enteredPIN1.isEmpty {
            withAnimation {
                error = nil
            }
        }

        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || !enteredPIN2.isEmpty
        }
        
        if enteredPIN1.count == 6 {
            focusPIN2 = true
        }
        
        return .none
    }
    
    mutating func handlePIN2Change(_ enteredPIN2: String, environment: AppEnvironment) -> Effect<FirstTimeUserPersonalPINAction, Never> {
        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || !enteredPIN2.isEmpty
        }
        
        guard enteredPIN2.count == 6 else { return .none }
        guard enteredPIN1 == enteredPIN2 else {
            withAnimation {
                attempts += 1
            }
            return Effect(value: withAnimation { .reset })
                .delay(for: 0.2, scheduler: environment.mainQueue.animation(.linear(duration: 0.2)))
                .eraseToEffect()
        }
        
        return Effect(value: .done(pin: enteredPIN2))
    }
}

enum FirstTimeUserPersonalPINAction: BindableAction, Equatable {
    case onAppear
    case done(pin: String)
    case reset
    case binding(BindingAction<FirstTimeUserPersonalPINState>)
}

let firstTimeUserPersonalPINReducer = Reducer<FirstTimeUserPersonalPINState, FirstTimeUserPersonalPINAction, AppEnvironment> { state, action, environment in
    switch action {
    case .onAppear:
        return .none
    case .binding(\.$enteredPIN1):
        return state.handlePIN1Change(state.enteredPIN1)
    case .binding(\.$enteredPIN2):
        return state.handlePIN2Change(state.enteredPIN2, environment: environment)
    case .binding:
        return .none
    case .reset:
        state.error = .mismatch
        state.showPIN2 = false
        state.enteredPIN2 = ""
        state.enteredPIN1 = ""
        state.focusPIN1 = true
        return .none
    case .done(pin: let pin):
        print(pin)
        return .none
    }
}.binding()
