import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct CoordinatorView: View {
    let store: Store<CoordinatorState, CoordinatorAction>
    
    var body: some View {
        TCARouter(store) { screen in
            // `SwitchStore` allows only 9 `CaseLet`s, therefore we use
            // this ZStack with multiple `SwitchStore`s as workaround
            ZStack {
                SwitchStore(screen) {
                    CaseLet(state: /ScreenState.home,
                            action: ScreenAction.home,
                            then: HomeView.init)
                    CaseLet(state: /ScreenState.setupIntro,
                            action: ScreenAction.setupIntro,
                            then: SetupIntro.init)
                    CaseLet(state: /ScreenState.setupTransportPINIntro,
                            action: ScreenAction.setupTransportPINIntro,
                            then: SetupTransportPINIntro.init)
                    CaseLet(state: /ScreenState.setupTransportPIN,
                            action: ScreenAction.setupTransportPIN,
                            then: SetupTransportPIN.init)
                    CaseLet(state: /ScreenState.setupPersonalPINIntro,
                            action: ScreenAction.setupPersonalPINIntro,
                            then: SetupPersonalPINIntro.init)
                    CaseLet(state: /ScreenState.setupPersonalPIN,
                            action: ScreenAction.setupPersonalPIN,
                            then: SetupPersonalPIN.init)
                    CaseLet(state: /ScreenState.setupScan,
                            action: ScreenAction.setupScan,
                            then: SetupScan.init)
                    Default { }
                }
                SwitchStore(screen) {
                    CaseLet(state: /ScreenState.setupDone,
                            action: ScreenAction.setupDone,
                            then: SetupDone.init)
                    CaseLet(state: /ScreenState.setupCardDeactivated,
                            action: ScreenAction.setupCardDeactivated,
                            then: SetupCardDeactivated.init)
                    CaseLet(state: /ScreenState.setupIncorrectTransportPIN,
                            action: ScreenAction.setupIncorrectTransportPIN,
                            then: SetupIncorrectTransportPIN.init)
                    Default { }
                }
            }
        }
    }
}
