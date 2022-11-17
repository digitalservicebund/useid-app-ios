import ComposableArchitecture
import Foundation
import Analytics

struct SetupScreen: ReducerProtocol {
    enum State: Equatable {
        case intro(SetupIntro.State)
        case transportPINIntro
        case transportPIN(SetupTransportPIN.State)
        case personalPINIntro
        case personalPINInput(SetupPersonalPINInput.State)
        case personalPINConfirm(SetupPersonalPINConfirm.State)
        case scan(SetupScan.State)
        case done(SetupDone.State)
        case incorrectTransportPIN(SetupIncorrectTransportPIN.State)
        case error(ScanError.State)
        case missingPINLetter(MissingPINLetter.State)
    }
    
    enum Action: Equatable {
        case intro(SetupIntro.Action)
        case transportPINIntro(SetupTransportPINIntroAction)
        case transportPIN(SetupTransportPIN.Action)
        case personalPINIntro(SetupPersonalPINIntroAction)
        case personalPINInput(SetupPersonalPINInput.Action)
        case personalPINConfirm(SetupPersonalPINConfirm.Action)
        case scan(SetupScan.Action)
        case done(SetupDone.Action)
        case incorrectTransportPIN(SetupIncorrectTransportPIN.Action)
        case error(ScanError.Action)
        case missingPINLetter(MissingPINLetter.Action)
    }
    
    var body: some ReducerProtocol<State, Action> {
        Scope(state: /State.transportPIN, action: /Action.transportPIN) {
            SetupTransportPIN()
        }
        Scope(state: /State.personalPINInput, action: /Action.personalPINInput) {
            SetupPersonalPINInput()
        }
        Scope(state: /State.personalPINConfirm, action: /Action.personalPINConfirm) {
            SetupPersonalPINConfirm()
        }
        Scope(state: /State.scan, action: /Action.scan) {
            SetupScan()
        }
        Scope(state: /State.incorrectTransportPIN, action: /Action.incorrectTransportPIN) {
            SetupIncorrectTransportPIN()
        }

        Scope(state: /State.missingPINLetter, action: /Action.missingPINLetter) {
            MissingPINLetter()
        }
        
        Scope(state: /State.error, action: /Action.error) {
            ScanError()
        }

    }
}

extension SetupScreen.State: AnalyticsView {
    var route: [String] {
        switch self {
        case .intro:
            return ["intro"]
        case .transportPINIntro:
            return ["PINLetter"]
        case .transportPIN:
            return ["transportPIN"]
        case .personalPINIntro:
            return ["personalPINIntro"]
        case .personalPINInput:
            return ["personalPINInput"]
        case .personalPINConfirm:
            return ["personalPINConfirm"]
        case .scan:
            return ["scan"]
        case .done:
            return ["done"]
        case .incorrectTransportPIN:
            return ["incorrectTransportPIN"]
        case .error(let state):
            return state.errorType.route
        case .missingPINLetter:
            return ["missingPINLetter"]
        }
    }
}
