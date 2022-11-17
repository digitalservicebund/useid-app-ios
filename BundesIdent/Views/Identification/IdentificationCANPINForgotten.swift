import SwiftUI
import Foundation
import ComposableArchitecture

struct IdentificationCANPINForgottenState: Equatable {
    let request: EIDAuthenticationRequest
    var pinCANCallback: PINCANCallback
}

enum IdentificationCANPINForgottenAction: Equatable {
    case orderNewPIN
    case showCANIntro(EIDAuthenticationRequest, PINCANCallback)
    case end
}

var identificationCanPINForgottenReducer = Reducer<IdentificationCANPINForgottenState, IdentificationCANPINForgottenAction, AppEnvironment> { _, action, _ in
    switch action {
    default:
        return .none
    }
}

struct IdentificationCANPINForgotten: View {
    var store: Store<IdentificationCANPINForgottenState, IdentificationCANPINForgottenAction>
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
                    Button {
                        ViewStore(store.stateless).send(.end)
                    } label: {
                        Text(verbatim: L10n.General.cancel)
                    }
                }
            }
    }
}

struct IdentificationCANPINForgotten_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationCANPINForgotten(store: .init(initialState: .init(request: .preview, pinCANCallback: PINCANCallback(id: UUID(), callback: { _, _ in })), reducer: identificationCanPINForgottenReducer, environment: AppEnvironment.preview))
    }
}
