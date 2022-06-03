import Foundation
import SwiftUI

extension View {
    public func interactiveDismissDisabled(onAttemptToDismiss: (() -> Void)? = nil) -> some View {
        InteractiveDismissableView(view: self, onAttemptToDismiss: onAttemptToDismiss)
    }
}

class SubHostingController<T: View>: UIHostingController<T>, UIAdaptivePresentationControllerDelegate {
    
    let onAttemptToDismiss: (() -> Void)?
    
    init(rootView: T, onAttemptToDismiss: (() -> Void)?) {
        self.onAttemptToDismiss = onAttemptToDismiss
        super.init(rootView: rootView)
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }
    
    override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        parent?.presentationController?.delegate = self
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        onAttemptToDismiss?()
    }
}

struct InteractiveDismissableView<T: View>: UIViewControllerRepresentable {
    
    let view: T
    let onAttemptToDismiss: (() -> Void)?
    
    func makeUIViewController(context: Context) -> UIHostingController<T> {
        SubHostingController(rootView: view, onAttemptToDismiss: onAttemptToDismiss)
    }
    
    func updateUIViewController(_ uiViewController: UIHostingController<T>, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject { }
}
