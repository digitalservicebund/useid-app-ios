import SwiftUI
import ComposableArchitecture

struct IdentificationCANIntroState: Equatable {
    let request: EIDAuthenticationRequest
    var shouldDismiss: Bool
}

enum IdentificationCANIntroAction: Equatable {
    case showInput(EIDAuthenticationRequest, Bool)
    case end
}

var identificationCANIntroRedcuer = Reducer<IdentificationCANIntroState, IdentificationCANIntroAction, AppEnvironment>.init { _, action, _ in
    switch action {
    default:
        return .none
    }
}

struct IdentificationCANIntro: View {
    var store: Store<IdentificationCANIntroState, IdentificationCANIntroAction>
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless, title: L10n.Identification.Can.Intro.title,
                       message: L10n.Identification.Can.Intro.body,
                       imageMeta: ImageMeta(asset: Asset.idCan),
                       primaryButton: .init(title: L10n.Identification.Can.Intro.continue, action: .showInput(viewStore.request, viewStore.shouldDismiss)))
            
            .navigationBarBackButtonHidden(viewStore.shouldDismiss)
            .navigationBarItems(leading: viewStore.shouldDismiss ? cancelButton(viewStore: viewStore) : nil)
        }
    }
    
    @ViewBuilder
    func cancelButton(viewStore: ViewStore<IdentificationCANIntroState, IdentificationCANIntroAction>) -> some View {
        Button(L10n.General.cancel) {
            ViewStore(store.stateless).send(.end)
        }
        .bodyLRegular(color: .accentColor)
        
    }
}
                                
struct IdentificationCANIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationCANIntro(store: .init(initialState: .init(request: .preview, shouldDismiss: true),
                                                reducer: identificationCANIntroRedcuer,
                                                environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
