import Sentry
import Analytics
import OSLog

struct SentryIssueTracker: IssueTracker {
    func addBreadcrumb(crumb: Breadcrumb) {
        let sentryCrumb = Sentry.Breadcrumb()
        sentryCrumb.level = crumb.level.sentryLevel
        sentryCrumb.category = crumb.category
        sentryCrumb.message = crumb.message
        SentrySDK.addBreadcrumb(crumb: sentryCrumb)
    }
    
    func capture(error: CustomNSError) {
        SentrySDK.capture(error: error)
    }
}

struct Breadcrumb {
    enum Level: String {
        case info

        var sentryLevel: SentryLevel {
            switch self {
            case .info: return .info
            }
        }
    }
    let level: Level
    let category: String
    var message: String?
}

extension IssueTracker {
    func addViewBreadcrumb(view: AnalyticsView) {
        let breadcrumb = Breadcrumb(level: .info, category: view.route.joined(separator: "/"))
        addBreadcrumb(crumb: breadcrumb)
    }

    func addInfoBreadcrumb(category: String, message: String) {
        let breadcrumb = Breadcrumb(level: .info, category: category, message: message)
        addBreadcrumb(crumb: breadcrumb)
    }
}

struct LogIssueTracker: IssueTracker {
    
    func addBreadcrumb(crumb: Breadcrumb) {
        var literal = "[\(crumb.level.rawValue)] \(crumb.category)"
        if let message = crumb.message {
            literal.append(" \(message)")
        }
        os_log(.debug, "Breadcrumb added: \(literal)")
    }
    
    func capture(error: CustomNSError) {
        os_log(.error, "Error captured: \(error)")
    }
}
