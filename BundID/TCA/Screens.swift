import ComposableArchitecture

enum ScreenState: Equatable {
    case home
    case setupIntro
    case setupTransportPINIntro
    case setupTransportPIN(SetupTransportPINState)
    case setupPersonalPINIntro
    case setupPersonalPIN(SetupPersonalPINState)
    case setupScan(SetupScanState)
    case setupDone
    case setupIncorrectTransportPIN(SetupIncorrectTransportPINState)
    case setupCardDeactivated
}

enum ScreenAction: Equatable {
    case home(HomeAction)
    case setupIntro(SetupIntroAction)
    case setupTransportPINIntro(SetupTransportPINIntroAction)
    case setupTransportPIN(SetupTransportPINAction)
    case setupPersonalPINIntro(SetupPersonalPINIntroAction)
    case setupPersonalPIN(SetupPersonalPINAction)
    case setupScan(SetupScanAction)
    case setupDone(SetupDoneAction)
    case setupIncorrectTransportPIN(SetupIncorrectTransportPINAction)
    case setupCardDeactivated(SetupCardDeactivatedAction)
}

let screenReducer = Reducer<ScreenState, ScreenAction, AppEnvironment>.combine(
    setupTransportPINReducer
        .pullback(
            state: /ScreenState.setupTransportPIN,
            action: /ScreenAction.setupTransportPIN,
            environment: { $0 }
        ),
    setupPersonalPINReducer
        .pullback(
            state: /ScreenState.setupPersonalPIN,
            action: /ScreenAction.setupPersonalPIN,
            environment: { $0 }
        ),
    setupScanReducer
        .pullback(
            state: /ScreenState.setupScan,
            action: /ScreenAction.setupScan,
            environment: { $0 }
        ),
    setupIncorrectTransportPINReducer
        .pullback(
            state: /ScreenState.setupIncorrectTransportPIN,
            action: /ScreenAction.setupIncorrectTransportPIN,
            environment: { $0 }
        )
)
