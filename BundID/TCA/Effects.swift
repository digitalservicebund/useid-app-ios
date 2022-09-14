import ComposableArchitecture
import Analytics

// MARK: Open URL

extension Effect {
    static func openURL(_ url: URL, urlOpener: @escaping (URL) -> Void) -> Effect {
        .fireAndForget {
            urlOpener(url)
        }
    }
}

// MARK: Analytics

extension Effect {
    static func trackEvent(category: String,
                           action: String,
                           name: String? = nil,
                           value: Float? = nil,
                           analytics: AnalyticsClient) -> Effect {
        .fireAndForget {
            let event = AnalyticsEvent(category: category, action: action, name: name, value: value)
            analytics.track(event: event)
        }
    }
}
