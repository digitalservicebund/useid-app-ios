import Analytics
import OSLog
import Sentry

struct SentryIssueTracker: IssueTracker {
    func addBreadcrumb(crumb: Breadcrumb) {
        SentrySDK.addBreadcrumb(crumb: crumb)
    }
    
    func capture(error: CustomNSError) {
        SentrySDK.capture(error: error)
    }
}

extension IssueTracker {
    func addViewBreadcrumb(view: AnalyticsView) {
        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = view.route.joined(separator: "/")
        addBreadcrumb(crumb: breadcrumb)
    }
}

struct LogIssueTracker: IssueTracker {
    
    func addBreadcrumb(crumb: Breadcrumb) {
        os_log(.debug, "Breadcrumb added: \(crumb)")
    }
    
    func capture(error: CustomNSError) {
        os_log(.error, "Error captured: \(error)")
    }
}
