import StoreKit
import Dependencies

struct ReviewController: ReviewControllerType {
    
    @Dependency(\.logger) var logger
    
    func requestReview() {
        guard !CommandLine.arguments.contains(LaunchArgument.suppressReview) else { return }
        guard let scene = UIApplication.activeScene else {
            logger.warning("Could not determine active scene to ask for review")
            return
        }
        SKStoreReviewController.requestReview(in: scene)
    }
}

private extension UIApplication {
    static var activeScene: UIWindowScene? {
        let foregroundActiveScene = shared.connectedScenes.first { $0.activationState == .foregroundActive }
        let foregroundInactiveScene = shared.connectedScenes.first { $0.activationState == .foregroundInactive }
        return (foregroundActiveScene ?? foregroundInactiveScene) as? UIWindowScene
    }
}
