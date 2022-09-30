import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    
    var name: String
    var loopMode: LottieLoopMode = .loop
    var cache: LRUAnimationCache = .sharedCache
    var backgroundColor: SwiftUI.Color?
    var accessiblityLabel: String?
    @Binding var syncedTime: AnimationProgressTime
    
    static let ANIMATION_VIEW_TAG = 1

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.backgroundColor = backgroundColor != nil ? UIColor(backgroundColor!) : nil
        animationView.tag = LottieView.ANIMATION_VIEW_TAG
        
        let view = UIView(frame: .zero)
        view.accessibilityTraits = .image
        view.isAccessibilityElement = accessiblityLabel != nil
        view.accessibilityLabel = accessiblityLabel
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        Task {
            let animation = Animation.named(name, animationCache: cache)
            await MainActor.run {
                animationView.animation = animation
                animationView.currentProgress = syncedTime
                animationView.play()
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
        // swiftlint:disable:next force_cast
        let animationView = uiView.viewWithTag(LottieView.ANIMATION_VIEW_TAG) as! AnimationView
        DispatchQueue.main.async {
            syncedTime = animationView.realtimeAnimationProgress
        }
    }
}
