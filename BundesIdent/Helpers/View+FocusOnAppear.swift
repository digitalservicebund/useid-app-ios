import ComposableArchitecture
import SwiftUI

extension View {
    /// Works like `onAppear` while allowing to change focus state.
    /// (Regular `onAppear` does not allow to change focus state on iOS 15 without a delay.)
    func focusOnAppear(perform action: (() -> Void)? = nil) -> some View {
        if #available(iOS 16, *) {
            return onAppear(perform: action)
        } else {
            return onAppear {
                // On iOS 15, setting a focus state only works after a short delay
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.75) {
                    action?()
                }
            }
        }
    }
}
