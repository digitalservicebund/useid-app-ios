import Foundation
import SwiftUI
import ComposableArchitecture

struct IdentificationShare: ReducerProtocol {
    struct State: Equatable {
        let request: EIDAuthenticationRequest
        let redirectURL: URL
        
        var formattedRedirectURL: String {
            var string = redirectURL.absoluteString
            guard let range = string.range(of: "https://") else {
                return string
            }
            string.removeSubrange(range)
            return string
        }
    }
    
    enum Action: Equatable {
        case close
        case share
    }
    
    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct IdentificationShareView: View {
    let store: StoreOf<IdentificationShare>
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.Identification.Share.title)
                    WithViewStore(store) { viewStore in
                        HStack {
                            Asset.bundesIdentIcon.swiftUIImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(5)
                            if #available(iOS 16.0, *) {
                                ShareLink(item: viewStore.redirectURL) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(viewStore.formattedRedirectURL)
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                            }
                        }
                        .frame(height: 24)
                        .bodyLBold()
                        .fixedSize()
                    }
                }
                .padding(.horizontal)
            }
            DialogButtons(store: store.stateless, secondary: .init(title: L10n.Identification.Share.close, action: .close), primary: nil)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IdentificationShareView_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationShareView(
            store: .init(
                initialState: .init(request: .preview,
                                    redirectURL: URL(string: "https://bundesident.de/yx29ejm")!),
                reducer: EmptyReducer())
        )
    }
}
