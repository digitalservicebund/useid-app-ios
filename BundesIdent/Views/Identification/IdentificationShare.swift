import Foundation
import SwiftUI
import ComposableArchitecture

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
            return email.isEmpty
        }
    }
    
    enum Action: Equatable, BindableAction {
        case close
        case confirmClose
        case send
        case sent(success: Bool, request: EIDAuthenticationRequest)
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
            case .send:
                let request = state.request
                let email = state.email
                return .run { send in
                    // TODO: Send to backend
                    do {
                        throw Error.emailError
                        await send(.sent(success: true, request: request))
                    } catch {
                        logger.error("Could not send email request: \(error)")
                        await send(.sent(success: false, request: request))
                    }
                }
            case .sent(success: false, request: _):
                state.alert = AlertState(title: TextState(L10n.Identification.Share.Email.Error.title),
                                         message: TextState(L10n.Identification.Share.Email.Error.body))
                return .none
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
                                .cornerRadius(5)
                                .frame(height: 30)
                            if #available(iOS 16.0, *) {
                                ShareLink(item: viewStore.redirectURL) {
                                    HStack(alignment: .firstTextBaseline) {
                                        Text(viewStore.formattedRedirectURL)
                                        Image(systemName: "square.and.arrow.up")
                                    }
                                }
                            }
                        }
                        .headingM()
                        .fixedSize()
                        .padding()
                    }
                    WithViewStore(store) { viewStore in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(L10n.Identification.Share.Email.title)
                                .bodyLRegular()
                                .padding(.horizontal)
                            TextField(L10n.Identification.Share.Email.placeholder, text: viewStore.binding(\.$email))
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding(.horizontal)
                                .textFieldStyle(BundTextFieldStyle())
                            DialogButtons(store: store.stateless, primary: .init(title: L10n.Identification.Share.Email.send, action: .send))
                                .disabled(viewStore.sendButtonDisabled)
                        }
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
                                    redirectURL: URL(string: "https://bundesident.de/yx29ejm")!),
                reducer: EmptyReducer())
        )
        IdentificationShareView(
            store: .init(
                initialState: .init(request: .preview,
                                    redirectURL: URL(string: "https://bundesident.de/yx29ejm")!,
                                    email: "abc@example.org"),
                reducer: EmptyReducer())
        )
    }
}
