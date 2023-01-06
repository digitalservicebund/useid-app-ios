import SwiftUI

public extension View {
    func onInitialAppear(_ action: @escaping () -> Void) -> some View {
        modifier(InitialAppear(action: action))
    }
}

private struct InitialAppear: ViewModifier {
    let action: () -> Void
    
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}
