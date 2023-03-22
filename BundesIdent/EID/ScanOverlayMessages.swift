import Foundation

struct ScanOverlayMessages: Equatable {
    let sessionStarted: String
    let sessionFailed: String
    let sessionSucceeded: String
    let sessionInProgress: String

    static let setup: Self = .unified
    static let identification: Self = .unified

    private static let unified: Self = .init(sessionStarted: L10n.Scan.Overlay.started,
                                             sessionFailed: L10n.Scan.Overlay.failed,
                                             sessionSucceeded: L10n.Scan.Overlay.succeeded,
                                             sessionInProgress: L10n.Scan.Overlay.progress)
}
