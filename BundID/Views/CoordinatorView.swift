import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct CoordinatorView: View {
    let store: Store<CoordinatorState, CoordinatorAction>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /ScreenState.home,
                        action: ScreenAction.home,
                        then: HomeView.init)
                CaseLet(state: /ScreenState.setupCoordinator,
                        action: ScreenAction.setupCoordinator,
                        then: SetupCoordinatorView.init)
            }
        }
    }
}

struct SetupCoordinatorView: View {
    let store: Store<SetupCoordinatorState, SetupCoordinatorAction>
    
    var body: some View {
        TCARouter(store) { screen in
            SwitchStore(screen) {
                CaseLet(state: /SetupScreenState.intro,
                        action: SetupScreenAction.intro,
                        then: SetupIntro.init)
                CaseLet(state: /SetupScreenState.transportPINIntro,
                        action: SetupScreenAction.transportPINIntro,
                        then: SetupTransportPINIntro.init)
                CaseLet(state: /SetupScreenState.transportPIN,
                        action: SetupScreenAction.transportPIN,
                        then: SetupTransportPIN.init)
                CaseLet(state: /SetupScreenState.personalPINIntro,
                        action: SetupScreenAction.personalPINIntro,
                        then: SetupPersonalPINIntro.init)
                CaseLet(state: /SetupScreenState.personalPIN,
                        action: SetupScreenAction.personalPIN,
                        then: SetupPersonalPIN.init)
                CaseLet(state: /SetupScreenState.scan,
                        action: SetupScreenAction.scan,
                        then: SetupScan.init)
                CaseLet(state: /SetupScreenState.done,
                        action: SetupScreenAction.done,
                        then: SetupDone.init)
                CaseLet(state: /SetupScreenState.error,
                        action: SetupScreenAction.error,
                        then: SetupError.init)
                CaseLet(state: /SetupScreenState.incorrectTransportPIN,
                        action: SetupScreenAction.incorrectTransportPIN,
                        then: SetupIncorrectTransportPIN.init)
            }
        }
    }
}
