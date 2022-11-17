import SwiftUI
import ComposableArchitecture

struct SetupDone: ReducerProtocol {
    struct State: Equatable {
        var tokenURL: URL?
        
        var primaryButton: DialogButtons<SetupDone.Action>.ButtonConfiguration {
            guard let tokenURL = tokenURL else {
                return .init(title: L10n.FirstTimeUser.Done.close,
                             action: .done)
            }
            
            return .init(title: L10n.FirstTimeUser.Done.identify,
                         action: .triggerIdentification(tokenURL: tokenURL))
        }
    }

    enum Action: Equatable {
        case done
        case triggerIdentification(tokenURL: URL)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}

struct SetupDoneView: View {
    
    var store: Store<SetupDone.State, SetupDone.Action>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.FirstTimeUser.Done.title,
                       imageMeta: ImageMeta(asset: Asset.eiDs),
                       primaryButton: viewStore.primaryButton)
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false)
        .interactiveDismissDisabled()
    }
    
}

struct SetupDone_Previews: PreviewProvider {
    static var previews: some View {
        SetupDoneView(store: Store(initialState: SetupDone.State(), reducer: SetupDone()))
    }
}
