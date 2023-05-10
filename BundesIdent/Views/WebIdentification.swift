import SwiftUI
import WebKit
import ComposableArchitecture

struct WebIdentification: ReducerProtocol {

    struct State: Equatable {
        var url: String
    }

    enum Action: Equatable {
        case triggerIdentification(tokenURL: URL)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct WebIdentificationView: View {

    var store: StoreOf<WebIdentification>

    var body: some View {
        WithViewStore(store) { viewStore in
            IdentificationOverridingWebView(url: viewStore.url) { url in
                viewStore.send(.triggerIdentification(tokenURL: url))
            }
        }
    }
}

private struct IdentificationOverridingWebView: UIViewRepresentable {
    let url: String
    let onTriggerIdentification: (URL) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.navigationDelegate = context.coordinator
        return view
    }

    func updateUIView(_ view: WKWebView, context: UIViewRepresentableContext<IdentificationOverridingWebView>) {
        let request = URLRequest(url: URL(string: url)!)
        view.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var view: IdentificationOverridingWebView

        init(_ parent: IdentificationOverridingWebView) {
            self.view = parent
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let navigationURL = navigationAction.request.url,
               let tokenURL = extractTCTokenURL(url: navigationURL) {
                view.onTriggerIdentification(tokenURL)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func extractTCTokenURL(url: URL) -> URL? {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems,
                  let urlString = queryItems.last(where: { $0.name == "tcTokenURL" && $0.value != nil })?.value
            else { return nil }

            return URL(string: urlString)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
