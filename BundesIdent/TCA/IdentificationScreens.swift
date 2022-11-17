import Foundation
import ComposableArchitecture
import Analytics

enum IdentificationScreenState: Equatable, IDInteractionHandler {
    case overview(IdentificationOverviewState)
    case personalPIN(IdentificationPersonalPINState)
    case incorrectPersonalPIN(IdentificationIncorrectPersonalPINState)
    case canPINForgotten(IdentificationCANPINForgottenState)
    case canOrderNewPIN(IdentificationCANOrderNewPINState)
    case canIntro(IdentificationCANIntroState)
    case canInput(IdentificationCANInputState)
    case canPersonalPINInput(IdentificationCANPersonalPINInputState)
    case canIncorrectInput(IdentificationCANIncorrectInputState)
    case scan(IdentificationScanState)
    case canScan(IdentificationCANScanState)
    case error(ScanErrorState)
    
    func transformToLocalAction(_ event: Result<EIDInteractionEvent, IDCardInteractionError>) -> IdentificationScreenAction? {
        switch self {
        case .overview(let state):
            guard let localAction = state.transformToLocalAction(event) else { return nil }
            return .overview(localAction)
        case .scan(let state):
            guard let localAction = state.transformToLocalAction(event) else { return nil }
            return .scan(localAction)
        case .canScan(let state):
            guard let localAction = state.transformToLocalAction(event) else { return nil }
            return .canScan(localAction)
        default:
            return nil
        }
    }
    
    var swipeToDismissState: SwipeToDismissState {
        switch self {
        case .overview: return .allowAfterConfirmation
        case .personalPIN: return .block
        case .scan: return .allowAfterConfirmation
        case .canScan: return .allowAfterConfirmation
        // handled by screen reducers
        case .incorrectPersonalPIN: return .allow
        case .canPINForgotten: return .allowAfterConfirmation
        case .canOrderNewPIN: return .block
        case .canIntro(let state):
            return state.shouldDismiss ? .allowAfterConfirmation : .block
        case .canInput: return .block
        case .canPersonalPINInput: return .block
        case .canIncorrectInput: return .allowAfterConfirmation
        case .error: return .allow
        }
    }
}

extension IdentificationScreenState: AnalyticsView {
    var route: [String] {
        switch self {
        case .overview:
            return ["attributes"]
        case .scan:
            return ["scan"]
        case .canScan:
            return ["canScan"]
        case .personalPIN:
            return ["personalPIN"]
        case .incorrectPersonalPIN:
            return ["incorrectPersonalPIN"]
        case .canPINForgotten:
            return ["canPINForgotten"]
        case .canOrderNewPIN:
            return ["canOrderNewPIN"]
        case .canIntro:
            return ["canIntro"]
        case .canInput:
            return ["canInput"]
        case .canPersonalPINInput:
            return ["canPersonalPINInput"]
        case .canIncorrectInput:
            return ["canIncorrectInput"]
        case .error(let state):
            return state.errorType.route
        }
    }
}

enum IdentificationScreenAction: Equatable {
    case overview(IdentificationOverviewAction)
    case personalPIN(IdentificationPersonalPINAction)
    case incorrectPersonalPIN(IdentificationIncorrectPersonalPINAction)
    case scan(IdentificationScanAction)
    case canScan(IdentificationCANScanAction)
    case canPINForgotten(IdentificationCANPINForgottenAction)
    case orderNewPIN(IdentificationCANOrderNewPINAction)
    case canIntro(IdentificationCANIntroAction)
    case canInput(IdentificationCANInputAction)
    case canPersonalPINInput(IdentificationCANPersonalPINInputAction)
    case canIncorrectInput(IdentificationCANIncorrectInputAction)
    case error(ScanErrorAction)
}

let identificationScreenReducer = Reducer<IdentificationScreenState, IdentificationScreenAction, AppEnvironment>.combine(
    identificationOverviewReducer
        .pullback(
            state: /IdentificationScreenState.overview,
            action: /IdentificationScreenAction.overview,
            environment: { $0 }
        ),
    identificationPersonalPINReducer
        .pullback(
            state: /IdentificationScreenState.personalPIN,
            action: /IdentificationScreenAction.personalPIN,
            environment: { $0 }
        ),
    identificationIncorrectPersonalPINReducer
        .pullback(
            state: /IdentificationScreenState.incorrectPersonalPIN,
            action: /IdentificationScreenAction.incorrectPersonalPIN,
            environment: { $0 }
        ),
    identificationScanReducer
        .pullback(
            state: /IdentificationScreenState.scan,
            action: /IdentificationScreenAction.scan,
            environment: { $0 }
        ),
    identificationCANScanReducer
        .pullback(state: /IdentificationScreenState.canScan,
                  action: /IdentificationScreenAction.canScan,
                  environment: { $0 }
                 ),
    identificationCanPINForgottenReducer
        .pullback(state: /IdentificationScreenState.canPINForgotten,
                  action: /IdentificationScreenAction.canPINForgotten,
                  environment: { $0 }),
    identificationCANOrderNewPINReducer
        .pullback(state: /IdentificationScreenState.canOrderNewPIN,
                  action: /IdentificationScreenAction.orderNewPIN,
                  environment: { $0 }),
    identificationCANIntroRedcuer
        .pullback(state: /IdentificationScreenState.canIntro,
                  action: /IdentificationScreenAction.canIntro,
                  environment: { $0 }),
    identificationCANInputReducer
        .pullback(state: /IdentificationScreenState.canInput,
                  action: /IdentificationScreenAction.canInput,
                  environment: { $0 }),
    identificationCANPersonalPINInputReducer
        .pullback(state: /IdentificationScreenState.canPersonalPINInput,
                  action: /IdentificationScreenAction.canPersonalPINInput,
                  environment: { $0 }),
    identificationCANIncorrectInputReducer
        .pullback(state: /IdentificationScreenState.canIncorrectInput,
                  action: /IdentificationScreenAction.canIncorrectInput,
                  environment: { $0 }),
    scanErrorReducer
        .pullback(
            state: /IdentificationScreenState.error,
            action: /IdentificationScreenAction.error,
            environment: { $0 }
        )
)
