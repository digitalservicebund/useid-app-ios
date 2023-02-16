import SwiftUI
import ComposableArchitecture

struct CANIntro: ReducerProtocol {
    struct State: Equatable {
        var isRootOfCANFlow: Bool
    }
    
    enum Action: Equatable {
        case showInput(isRootOfCANFlow: Bool)
        case end
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct CANIntroView: View {
    var store: StoreOf<CANIntro>
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless, title: L10n.Identification.Can.Intro.title,
                       message: L10n.Identification.Can.Intro.body,
                       imageMeta: ImageMeta(asset: Asset.idCan),
                       primaryButton: .init(title: L10n.Identification.Can.Intro.continue, action: .showInput(isRootOfCANFlow: viewStore.isRootOfCANFlow)))
            
                .navigationBarBackButtonHidden(viewStore.isRootOfCANFlow)
                .navigationBarItems(leading: viewStore.isRootOfCANFlow ? cancelButton(viewStore: viewStore) : nil)
        }
    }
    
    @ViewBuilder
    func cancelButton(viewStore: ViewStore<CANIntro.State, CANIntro.Action>) -> some View {
        Button(L10n.General.cancel) {
            ViewStore(store.stateless).send(.end)
        }
        .bodyLRegular(color: .accentColor)
    }
}

#if DEBUG

struct CANIntro_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CANIntroView(store: .init(initialState: .init(isRootOfCANFlow: true),
                                      reducer: CANIntro()))
        }
        .previewDevice("iPhone 12")
    }
}

#endif
