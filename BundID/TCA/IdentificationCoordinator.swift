import Foundation
import FlowStacks
import TCACoordinators
import IdentifiedCollections
import SwiftUI
import ComposableArchitecture

struct IdentificationCoordinatorState: Equatable, IndexedRouterState {
    var tokenURL: String
    var token: IdentificationOverviewLoadedState?
    var pin: String = ""
    var routes: [Route<IdentificationScreenState>] {
        get {
            states.map {
                $0.map { screenState in
                    switch screenState {
                    case .overview(var state):
                        state.tokenURL = tokenURL
                        return .overview(state)
                    default:
                        return screenState
                    }
                }
            }
        }
        set {
            states = newValue
        }
    }
    var states: [Route<IdentificationScreenState>]
    
    init(tokenURL: String) {
        self.tokenURL = tokenURL
        self.states = [.root(.overview(IdentificationOverviewState(tokenURL: tokenURL)))]
    }
}

enum IdentificationCoordinatorAction: Equatable, IndexedRouterAction {
    case routeAction(Int, action: IdentificationScreenAction)
    case updateRoutes([Route<IdentificationScreenState>])
}

let identificationCoordinatorReducer: Reducer<IdentificationCoordinatorState, IdentificationCoordinatorAction, AppEnvironment> = identificationScreenReducer
    .forEachIndexedRoute(environment: { $0 })
    .withRouteReducer(
        Reducer { state, action, _ in
            switch action {
            case .routeAction(_, action: .overview(.done)):
                state.routes.push(.personalPIN(IdentificationPersonalPINState()))
                return .none
            case .routeAction(_, action: .personalPIN(.done(pin: let pin))):
                state.pin = pin
                state.routes.push(.scan(IdentificationScanState(tokenURL: state.tokenURL, pin: state.pin)))
                return .none
            default:
                return .none
            }
        }
    )

struct IdentificationCoordinatorView: View {
    let store: Store<IdentificationCoordinatorState, IdentificationCoordinatorAction>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /IdentificationScreenState.overview,
                        action: IdentificationScreenAction.overview,
                        then: IdentificationOverview.init)
                CaseLet(state: /IdentificationScreenState.personalPIN,
                        action: IdentificationScreenAction.personalPIN,
                        then: IdentificationPersonalPIN.init)
                CaseLet(state: /IdentificationScreenState.scan,
                        action: IdentificationScreenAction.scan,
                        then: IdentificationScan.init)
            }
        }
    }
}
