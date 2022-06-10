import ComposableArchitecture

enum SetupScreenState: Equatable {
    case intro
    case transportPINIntro
    case transportPIN(SetupTransportPINState)
    case personalPINIntro
    case personalPIN(SetupPersonalPINState)
    case scan(SetupScanState)
    case done
    case incorrectTransportPIN(SetupIncorrectTransportPINState)
    case error(SetupErrorState)
}

enum SetupScreenAction: Equatable {
    case intro(SetupIntroAction)
    case transportPINIntro(SetupTransportPINIntroAction)
    case transportPIN(SetupTransportPINAction)
    case personalPINIntro(SetupPersonalPINIntroAction)
    case personalPIN(SetupPersonalPINAction)
    case scan(SetupScanAction)
    case done(SetupDoneAction)
    case incorrectTransportPIN(SetupIncorrectTransportPINAction)
    case error(SetupErrorAction)
}

let setupScreenReducer = Reducer<SetupScreenState, SetupScreenAction, AppEnvironment>.combine(
    setupTransportPINReducer
        .pullback(
            state: /SetupScreenState.transportPIN,
            action: /SetupScreenAction.transportPIN,
            environment: { $0 }
        ),
    setupPersonalPINReducer
        .pullback(
            state: /SetupScreenState.personalPIN,
            action: /SetupScreenAction.personalPIN,
            environment: { $0 }
        ),
    setupScanReducer
        .pullback(
            state: /SetupScreenState.scan,
            action: /SetupScreenAction.scan,
            environment: { $0 }
        ),
    setupIncorrectTransportPINReducer
        .pullback(
            state: /SetupScreenState.incorrectTransportPIN,
            action: /SetupScreenAction.incorrectTransportPIN,
            environment: { $0 }
        )
)
