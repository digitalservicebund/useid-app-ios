public struct AnalyticsEvent: Hashable {
    public let category: String
    public let action: String
    public let name: String?
    public let value: Float?
    
    public init(category: String, action: String, name: String? = nil, value: Float? = nil) {
        self.category = category
        self.action = action
        self.name = name
        self.value = value
    }
}

public protocol AnalyticsView {
    var route: [String] { get }
}

public protocol AnalyticsClient {
    func track(event: AnalyticsEvent)
    func track(view: AnalyticsView)

    func dispatch()
}
