import SwiftUI
import ComposableArchitecture
import StoreKit

struct SetupDone: ReducerProtocol {
    
    @Dependency(\.logger) var logger
    @Dependency(\.reviewController) var reviewController
    
    struct State: Equatable {
        var tokenURL: URL?
        
        var primaryButton: DialogButtons<SetupDone.Action>.ButtonConfiguration {
            guard let tokenURL else {
                return .init(title: L10n.FirstTimeUser.Done.close,
                             action: .done)
            }
            
            return .init(title: L10n.FirstTimeUser.Done.identify,
                         action: .triggerIdentification(tokenURL: tokenURL))
        }
    }

    enum Action: Equatable {
        case onInitialAppear
        case done
        case triggerIdentification(tokenURL: URL)
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onInitialAppear:
            guard state.tokenURL == nil else { return .none }
            reviewController.requestReview()
            return .none
        default:
            return .none
        }
    }
}

struct SetupDoneView: View {
    
    var store: Store<SetupDone.State, SetupDone.Action>
    @State var didAppear = false
    
    init(_ store: Store<SetupDone.State, SetupDone.Action>) {
        self.store = store
    }
    
    var body: some View {
        WithViewStore(store) { viewStore in
            DialogView(store: store.stateless,
                       title: L10n.FirstTimeUser.Done.title,
                       imageMeta: ImageMeta(asset: Asset.eiDs),
                       primaryButton: viewStore.primaryButton)
                .onAppear {
                    guard !didAppear else { return }
                    didAppear = true
                    viewStore.send(.onInitialAppear)
                }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false)
        .interactiveDismissDisabled()
    }
    
}

struct SetupDone_Previews: PreviewProvider {
    static var previews: some View {
        SetupDoneView(Store(initialState: SetupDone.State(), reducer: SetupDone()))
    }
}
