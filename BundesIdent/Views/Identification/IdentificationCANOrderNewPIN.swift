import ComposableArchitecture
import SwiftUI
import MarkdownUI

struct IdentificationCANOrderNewPIN: ReducerProtocol {
    struct State: Equatable {}
    
    struct Action: Equatable {}
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct IdentificationCANOrderNewPINView: View {
    var store: Store<IdentificationCANOrderNewPIN.State, IdentificationCANOrderNewPIN.Action>
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.Identification.Can.OrderNewPin.title)
                        .headingXL()
                    Markdown(L10n.Identification.Can.OrderNewPin.body)
                        .markdownTheme(.bund)
                        .fixedSize(horizontal: false, vertical: true)

                    if let imageMeta = ImageMeta(asset: Asset.missingPINBrief) {
                        imageMeta.image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: imageMeta.maxHeight)
                            .padding(.vertical, 10)
                    }
                }
            }
            .padding(.horizontal)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarHidden(false)
        .interactiveDismissDisabled(true)
    }
}

struct IdentificationCANOrderNewPIN_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            IdentificationCANOrderNewPINView(store: Store(initialState: IdentificationCANOrderNewPIN.State(),
                                                          reducer: IdentificationCANOrderNewPIN()))
        }
        .previewDevice("iPhone 12")
    }
}
