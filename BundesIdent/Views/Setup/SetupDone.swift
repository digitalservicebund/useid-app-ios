import SwiftUI
import ComposableArchitecture

struct SetupDone: ReducerProtocol {
    struct State: Equatable {
        var identificationInformation: IdentificationInformation?
        
        var primaryButton: DialogButtons<SetupDone.Action>.ButtonConfiguration {
            guard let identificationInformation else {
                return .init(title: L10n.FirstTimeUser.Done.close,
                             action: .done)
            }
            
            return .init(title: L10n.FirstTimeUser.Done.identify,
                         action: .triggerIdentification(identificationInformation: identificationInformation))
        }
    }

    enum Action: Equatable {
        case done
        case triggerIdentification(identificationInformation: IdentificationInformation)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
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
