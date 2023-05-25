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
