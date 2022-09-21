import ComposableArchitecture
import Analytics

enum SetupScreenState: Equatable {
    case intro(SetupIntroState)
    case transportPINIntro
    case transportPIN(SetupTransportPINState)
    case personalPINIntro
    case personalPIN(SetupPersonalPINState)
    case scan(SetupScanState)
    case done(SetupDoneState)
    case incorrectTransportPIN(SetupIncorrectTransportPINState)
    case error(ScanErrorState)
    case missingPINLetter(MissingPINLetterState)
}

extension SetupScreenState: AnalyticsView {
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
        case .personalPIN:
            return ["personalPIN"]
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

enum SetupScreenAction: Equatable {
    case intro(SetupIntroAction)
    case transportPINIntro(SetupTransportPINIntroAction)
    case transportPIN(SetupTransportPINAction)
    case personalPINIntro(SetupPersonalPINIntroAction)
    case personalPIN(SetupPersonalPINAction)
    case scan(SetupScanAction)
    case done(SetupDoneAction)
    case incorrectTransportPIN(SetupIncorrectTransportPINAction)
    case error(ScanErrorAction)
    case missingPINLetter(MissingPINLetterAction)
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
        ),
    missingPINLetterReducer
        .pullback(
            state: /SetupScreenState.missingPINLetter,
            action: /SetupScreenAction.missingPINLetter,
            environment: { $0 }
        )
)
