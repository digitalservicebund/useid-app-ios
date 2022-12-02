import ComposableArchitecture
import SwiftUI
import MarkdownUI

struct IdentificationCANOrderNewPINState: Equatable {
    
}

enum IdentificationCANOrderNewPINAction: Equatable {
    
}

var identificationCANOrderNewPINReducer: Reducer<IdentificationCANOrderNewPINState, IdentificationCANOrderNewPINAction, AppEnvironment> = .init { _, action, _ in
    switch action {
    default:
        return .none
    }
}

struct IdentificationCANOrderNewPIN: View {
    var store: Store<IdentificationCANOrderNewPINState, IdentificationCANOrderNewPINAction>
    var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(L10n.Identification.Can.OrderNewPin.title)
                            .headingXL()
                        Markdown(L10n.Identification.Can.OrderNewPin.body)
                            .markdownStyle(MarkdownStyle(font: .bundBody))
                            .foregroundColor(.blackish)
                            .fixedSize(horizontal: false, vertical: true)
                            .accentColor(.blue800)
                            
                        if let imageMeta = ImageMeta(asset: Asset.missingPINBrief) {
                            imageMeta.image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity, maxHeight: imageMeta.maxHeight)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal)
                }
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
            IdentificationCANOrderNewPIN(store: .init(initialState: .init(),
                                                   reducer: identificationCANOrderNewPINReducer,
                                                   environment: AppEnvironment.preview))
        }
        .previewDevice("iPhone 12")
    }
}
