import ComposableArchitecture

enum ScreenState: Equatable {
    case home
    case setupIntro
    case firstTimeUserPINLetter
    case firstTimeUserTransportPIN(FirstTimeUserTransportPINState)
    case firstTimeUserChoosePINIntro
    case firstTimeUserChoosePIN(FirstTimeUserPersonalPINState)
}

enum ScreenAction: Equatable {
    case home(HomeAction)
    case setupIntro(SetupIntroAction)
    case firstTimeUserPINLetter(FirstTimeUserPINLetterAction)
    case firstTimeUserTransportPIN(FirstTimeUserTransportPINAction)
    case firstTimeUserChoosePINIntro(FirstTimeUserChoosePINIntroAction)
    case firstTimeUserChoosePIN(FirstTimeUserPersonalPINAction)
}

let screenReducer = Reducer<ScreenState, ScreenAction, AppEnvironment>.combine(
    firstTimeUserTransportPINReducer
        .pullback(
            state: /ScreenState.firstTimeUserTransportPIN,
            action: /ScreenAction.firstTimeUserTransportPIN,
            environment: { $0 }
        ),
    firstTimeUserPersonalPINReducer
        .pullback(
            state: /ScreenState.firstTimeUserChoosePIN,
            action: /ScreenAction.firstTimeUserChoosePIN,
            environment: { $0 }
        )
)
