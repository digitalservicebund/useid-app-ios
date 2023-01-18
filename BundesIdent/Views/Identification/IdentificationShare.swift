import ComposableArchitecture
import Foundation
import SwiftUI

struct IdentificationShare: ReducerProtocol {
    
    @Dependency(\.logger) var logger
    
    struct State: Equatable {
        let request: EIDAuthenticationRequest
        let redirectURL: URL
        
        @BindableState var email: String = ""
        @BindableState var alert: AlertState<Action>?
        
        var formattedRedirectURL: String {
            var string = redirectURL.absoluteString
            guard let range = string.range(of: "https://") else {
                return string
            }
            string.removeSubrange(range)
            return string
        }
        
        var sendButtonDisabled: Bool {
            email.isEmpty
        }
    }
    
    enum Action: Equatable, BindableAction {
        case close
        case confirmClose
        case binding(BindingAction<State>)
        case dismissAlert
    }
    
    enum Error: Swift.Error {
        case emailError
    }
    
    var body: some ReducerProtocol<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .dismissAlert:
                state.alert = nil
                return .none
            case .close:
                state.alert = AlertState(title: TextState(L10n.Identification.Share.ConfirmClose.title),
                                         message: TextState(L10n.Identification.Share.ConfirmClose.body),
                                         primaryButton: .default(TextState(L10n.Identification.Share.ConfirmClose.close), action: .send(.confirmClose)),
                                         secondaryButton: .cancel(TextState(L10n.General.cancel)))
                return .none
            default:
                return .none
            }
        }
    }
}

struct IdentificationShareView: View {
    let store: StoreOf<IdentificationShare>
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HeaderView(title: L10n.Identification.Share.title)
                        .padding(.horizontal)
                    WithViewStore(store) { viewStore in
                        HStack {
                            Asset.bundesIdentIcon.swiftUIImage
                                .resizable()
                                .aspectRatio(contentMode: .fit)
//                                .cornerRadius(5)
                            Text(viewStore.formattedRedirectURL)
                                .headingM()
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .textSelection(.enabled)
                            Button {
                                let pasteboard = UIPasteboard.general
                                pasteboard.string = viewStore.redirectURL.absoluteString
                            } label: {
                                Label("Kopieren", systemImage: "doc.on.doc")
                                    .bodyMBold(color: .blue800)
                                    .padding(10)
                                    .background(Color.blue200)
                                    .cornerRadius(8)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(maxHeight: 30)
                        .padding()
                    }
                }
            }
            DialogButtons(store: store.stateless, secondary: .init(title: L10n.Identification.Share.close, action: .close), primary: nil)
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarTitleDisplayMode(.inline)
        .alert(store.scope(state: \.alert), dismiss: .dismissAlert)
    }
}

struct IdentificationShareView_Previews: PreviewProvider {
    static var previews: some View {
        IdentificationShareView(
            store: .init(
                initialState: .init(request: .preview,
                                    redirectURL: URL(string: "https://buid.de/yx29ejm")!),
                reducer: IdentificationShare()
            )
        )
        .previewDisplayName("Empty email")
        
        IdentificationShareView(
            store: .init(
                initialState: .init(request: .preview,
                                    redirectURL: URL(string: "https://bundesident.de/yx29ejm")!,
                                    email: "abc@example.org"),
                reducer: IdentificationShare()
            )
        )
        .previewDisplayName("Filled email")
        
        IdentificationShareView(
            store: .init(
                initialState: .init(request: .preview,
                                    redirectURL: URL(string: "https://bundesident.de/opsidfjksdhjfisdhaijsdhaijshdfiajshfijsdgfjoashfkjahsfjhsaf")!),
                reducer: IdentificationShare()
            )
        )
        .previewDisplayName("Very long link")
    }
}
