import SwiftUI
import ComposableArchitecture

struct SetupDoneState: Equatable {
    var tokenURL: String?
    
    var primaryButton: DialogButtons<SetupDoneAction>.ButtonConfiguration {
        guard let tokenURL = tokenURL else {
            return .init(title: L10n.FirstTimeUser.DoneConfirmation.confirm,
                         action: .done)
        }
        
        return .init(title: L10n.FirstTimeUser.DoneConfirmation.startIdentification,
                     action: .triggerIdentification(tokenURL: tokenURL))
    }
    
    var secondaryButton: DialogButtons<SetupDoneAction>.ButtonConfiguration? {
        guard tokenURL != nil else { return nil }
        
        return .init(title: L10n.FirstTimeUser.DoneConfirmation.confirm,
                     action: .done)
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
                       message: nil,
                       imageMeta: ImageMeta(name: "eIDs"),
                       secondaryButton: viewStore.secondaryButton,
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
