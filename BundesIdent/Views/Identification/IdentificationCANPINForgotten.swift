import SwiftUI
import Foundation
import ComposableArchitecture

struct IdentificationCANPINForgotten: ReducerProtocol {
    struct State: Equatable {
        let request: EIDAuthenticationRequest
        var pinCANCallback: PINCANCallback
    }

    enum Action: Equatable {
        case orderNewPIN
        case showCANIntro(EIDAuthenticationRequest, PINCANCallback)
        case end
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}

struct IdentificationCANPINForgottenView: View {
    var store: Store<IdentificationCANPINForgotten.State, IdentificationCANPINForgotten.Action>
    var body: some View {
            WithViewStore(store) { viewStore in
                DialogView(store: store.stateless, title: L10n.Identification.Can.PinForgotten.title,
                           message: L10n.Identification.Can.PinForgotten.body,
                           imageMeta: ImageMeta(asset: Asset.idConfused, maxHeight: 230),
                           secondaryButton: .init(title: L10n.Identification.Can.PinForgotten.retry, action: .showCANIntro(viewStore.request, viewStore.pinCANCallback)),
                           primaryButton: .init(title: L10n.Identification.Can.PinForgotten.orderNewPin, action: .orderNewPIN))
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L10n.General.cancel) {
                        ViewStore(store.stateless).send(.end)
                    }
                    .bodyLRegular(color: .accentColor)
                }
            }
    }
}

struct IdentificationCANPINForgotten_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationCANPINForgottenView(store: .init(initialState: .init(request: .preview,
                                                                           pinCANCallback: PINCANCallback(id: UUID(),
                                                                                                          callback: { _, _ in })),
                                                       reducer: IdentificationCANPINForgotten()))
    }
}
