import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    public static let analytics = Logger(subsystem: subsystem, category: "analytics")
}
