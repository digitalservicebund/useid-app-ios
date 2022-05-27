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
                CaseLet(state: /ScreenState.setupIntro,
                        action: ScreenAction.setupIntro,
                        then: SetupIntro.init)
                CaseLet(state: /ScreenState.firstTimeUserPINLetter,
                        action: ScreenAction.firstTimeUserPINLetter,
                        then: FirstTimeUserPINLetterScreen.init)
                CaseLet(state: /ScreenState.firstTimeUserTransportPIN,
                        action: ScreenAction.firstTimeUserTransportPIN,
                        then: FirstTimeUserTransportPINScreen.init)
                CaseLet(state: /ScreenState.firstTimeUserChoosePINIntro,
                        action: ScreenAction.firstTimeUserChoosePINIntro,
                        then: FirstTimeUserChoosePINIntroScreen.init)
                CaseLet(state: /ScreenState.firstTimeUserChoosePIN,
                        action: ScreenAction.firstTimeUserChoosePIN,
                        then: FirstTimeUserPersonalPINScreen.init)
                CaseLet(state: /ScreenState.setupScan,
                        action: ScreenAction.setupScan,
                        then: SetupScan.init)
            }
        }
    }
}
