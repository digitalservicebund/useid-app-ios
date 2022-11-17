import SwiftUI
import ComposableArchitecture

struct IdentificationCANIntro: ReducerProtocol {
    struct State: Equatable {
        let request: EIDAuthenticationRequest
        var pinCANCallback: PINCANCallback
        var shouldDismiss: Bool
    }
    
    enum Action: Equatable {
        case showInput(EIDAuthenticationRequest, PINCANCallback, Bool)
        case end
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}

struct IdentificationCANIntroView: View {
    var store: Store<IdentificationCANIntro.State, IdentificationCANIntro.Action>
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless, title: L10n.Identification.Can.Intro.title,
                       message: L10n.Identification.Can.Intro.body,
                       imageMeta: ImageMeta(asset: Asset.idCan),
                       primaryButton: .init(title: L10n.Identification.Can.Intro.continue, action: .showInput(viewStore.request, viewStore.pinCANCallback, viewStore.shouldDismiss)))
            
            .navigationBarBackButtonHidden(viewStore.shouldDismiss)
            .navigationBarItems(leading: viewStore.shouldDismiss ? cancelButton(viewStore: viewStore) : nil)
        }
    }
    
    @ViewBuilder
    func cancelButton(viewStore: ViewStore<IdentificationCANIntro.State, IdentificationCANIntro.Action>) -> some View {
        Button(L10n.General.cancel) {
            ViewStore(store.stateless).send(.end)
        }
        .bodyLRegular(color: .accentColor)
        
    }
}

struct IdentificationCANIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationCANIntroView(store: .init(initialState: .init(request: .preview, pinCANCallback: PINCANCallback(id: .zero, callback: { _, _ in }), shouldDismiss: true),
                                                    reducer: IdentificationCANIntro()))
        }
        .previewDevice("iPhone 12")
    }
}
