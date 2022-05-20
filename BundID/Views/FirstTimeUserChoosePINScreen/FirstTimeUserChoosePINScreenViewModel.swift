import SwiftUI
import Combine

class FirstTimeUserPersonalPINScreenViewModel: ObservableObject {
    
    @Published var enteredPIN1: String
    @Published var enteredPIN2: String
    @Published var showPIN2: Bool
    @Published var focusPIN1: Bool
    @Published var focusPIN2: Bool
    @Published var isFinished: Bool
    @Published var error: FirstTimeUserPersonalPINScreenError?
    @Published var attempts: Int
    
    var cancellables: Set<AnyCancellable> = Set()
    
    init(enteredPIN1: String = "",
         enteredPIN2: String = "",
         showPIN2: Bool = false,
         focusPIN1: Bool = true,
         focusPIN2: Bool = false,
         isFinished: Bool = false,
         error: FirstTimeUserPersonalPINScreenError? = nil,
         attempts: Int = 0) {
        self.enteredPIN1 = enteredPIN1
        self.enteredPIN2 = enteredPIN2
        self.showPIN2 = showPIN2
        self.focusPIN1 = focusPIN1
        self.focusPIN2 = focusPIN2
        self.isFinished = isFinished
        self.error = error
        self.attempts = attempts
        
        $enteredPIN1
            .sink(receiveValue: handlePIN1Change)
            .store(in: &cancellables)
        
        $enteredPIN2
            .sink(receiveValue: handlePIN2Change)
            .store(in: &cancellables)
    }
    
    private func handlePIN1Change(_ enteredPIN1: String) {
        if !enteredPIN1.isEmpty {
            withAnimation {
                error = nil
            }
        }

        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || !enteredPIN2.isEmpty
        }
        
        if enteredPIN1.count == 6 {
            focusPIN1 = false
            focusPIN2 = true
        }
    }
    
    private func handlePIN2Change(_ enteredPIN2: String) {
        withAnimation {
            showPIN2 = enteredPIN1.count >= 6 || !enteredPIN2.isEmpty
        }
        
        if enteredPIN2.count == 6 {
            if enteredPIN1 != enteredPIN2 {
                withAnimation {
                    attempts += 1
                }
                withAnimation(.default.delay(0.2)) {
                    self.error = .mismatch
                    self.showPIN2 = false
                    self.enteredPIN2 = ""
                    self.enteredPIN1 = ""
                    self.focusPIN2 = false
                    self.focusPIN1 = true
                }
            } else {
                isFinished = true
            }
        }
    }
}
