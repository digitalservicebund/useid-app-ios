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
        Reducer { _, _, _ in
            return .none
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
            }
        }
    }
}
