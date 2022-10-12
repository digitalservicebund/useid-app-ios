import Foundation
import SwiftUI

extension View {
    public func interactiveDismissDisabled(_ dismissDisabled: Bool = true, onAttemptToDismiss: (() -> Void)? = nil) -> some View {
        InteractiveDismissableView(view: self, dismissDisabled: dismissDisabled, onAttemptToDismiss: onAttemptToDismiss)
    }
}

class SubHostingController<T: View>: UIHostingController<T>, UIAdaptivePresentationControllerDelegate {
    
    let onAttemptToDismiss: (() -> Void)?
    var dismissDisabled: Bool
    
    init(rootView: T, dismissDisabled: Bool, onAttemptToDismiss: (() -> Void)?) {
        self.onAttemptToDismiss = onAttemptToDismiss
        self.dismissDisabled = dismissDisabled
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
        return !dismissDisabled
    }
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        onAttemptToDismiss?()
    }
}

struct InteractiveDismissableView<T: View>: UIViewControllerRepresentable {
    
    let view: T
    let dismissDisabled: Bool
    let onAttemptToDismiss: (() -> Void)?
    
    func makeUIViewController(context: Context) -> SubHostingController<T> {
        SubHostingController(rootView: view, dismissDisabled: dismissDisabled, onAttemptToDismiss: onAttemptToDismiss)
    }
    
    func updateUIViewController(_ subHostingController: SubHostingController<T>, context: Context) {
        subHostingController.dismissDisabled = dismissDisabled
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject { }
}
