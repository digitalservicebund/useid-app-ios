import SwiftUI
import ComposableArchitecture

struct SetupDoneState: Equatable {
    var tokenURL: String?
    
    var primaryButton: DialogButtons<SetupDoneAction>.ButtonConfiguration {
        guard let tokenURL = tokenURL else {
            return .init(title: L10n.FirstTimeUser.Done.close,
                         action: .done)
        }
        
        return .init(title: L10n.FirstTimeUser.Done.identify,
                     action: .triggerIdentification(tokenURL: tokenURL))
    }
}

enum SetupDoneAction: Equatable {
    case done
    case triggerIdentification(tokenURL: String)
}

struct SetupDone: View {
    
    var store: Store<SetupDoneState, SetupDoneAction>
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.FirstTimeUser.Done.title,
                       imageMeta: ImageMeta(asset: Asset.eiDs),
                       primaryButton: viewStore.primaryButton)
        }
        .navigationBarBackButtonHidden(true)
    }
    
}

struct SetupDone_Previews: PreviewProvider {
    static var previews: some View {
        SetupDone(store: Store(initialState: SetupDoneState(), reducer: .empty, environment: AppEnvironment.preview))
    }
}
