import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    
    var name: String
    var loopMode: LottieLoopMode = .loop
    var cache: LRUAnimationCache = .sharedCache
    var backgroundColor: SwiftUI.Color?

    func makeUIView(context: UIViewRepresentableContext<LottieView>) -> UIView {
        
        let animationView = AnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.backgroundColor = backgroundColor != nil ? UIColor(backgroundColor!) : nil
        
        let view = UIView(frame: .zero)
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        Task {
            let animation = Animation.named(name, animationCache: cache)
            await MainActor.run {
                animationView.animation = animation
                animationView.play()
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {
    }
}
