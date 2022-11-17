import ComposableArchitecture
import Foundation
import Analytics

// MARK: Open URL

extension Effect {
    static func openURL(_ url: URL, urlOpener: @escaping (URL) -> Void) -> EffectPublisher {
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
                           analytics: AnalyticsClient) -> EffectPublisher {
        .fireAndForget {
            let event = AnalyticsEvent(category: category, action: action, name: name, value: value)
            analytics.track(event: event)
        }
    }
}
