import SwiftUI
import ComposableArchitecture
import WebKit

struct WidgetSelbstauskunft: ReducerProtocol {
    typealias State = Void

    enum Action: Equatable {
        case triggerIdentification(tokenURL: URL)
    }

    func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        .none
    }
}

struct WidgetSelbstauskunftView: View {

    var store: StoreOf<WidgetSelbstauskunft>

    var body: some View {
        WithViewStore(store) { viewStore in
            WebView(url: "https://demo.useid.dev.ds4g.net") { url in
                viewStore.send(.triggerIdentification(tokenURL: url))
            }
        }
    }
}

struct WidgetSelbstauskunftView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetSelbstauskunftView(store: .empty)
    }
}

struct WebView: UIViewRepresentable {
    let url: String
    let onTriggerIdentification: (URL) -> Void

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView(frame: .zero)
        view.navigationDelegate = context.coordinator
        return view
    }

    func updateUIView(_ view: WKWebView, context: UIViewRepresentableContext<WebView>) {
        let request = URLRequest(url: URL(string: url)!)
        view.load(request)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var view: WebView

        init(_ parent: WebView) {
            self.view = parent
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let navigationURL = navigationAction.request.url,
               navigationURL.absoluteString.contains("eID-Client") == true,
               let tokenURL = extractTCTokenURL(url: navigationURL) {
                view.onTriggerIdentification(tokenURL)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }

        func extractTCTokenURL(url: URL) -> URL? {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                //issueTracker.capture(error: HandleURLError.componentsInvalid)
                return nil
            }
            guard let queryItem = queryItems.last(where: { $0.name == "tcTokenURL" && $0.value != nil }),
                  let urlString = queryItem.value else {
                //issueTracker.capture(error: HandleURLError.noTCTokenURLQueryItem)
                return nil
            }
            guard let url = URL(string: urlString) else {
                //issueTracker.capture(error: HandleURLError.tcTokenURLEncodingError)
                return nil
            }

            return url
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
