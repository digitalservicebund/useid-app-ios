import SwiftUI

extension Shape {
    public func fill<S: ShapeStyle>(_ fillContent: S,
                                    opacity: Double = 1.0,
                                    strokeWidth: CGFloat = 1.0,
                                    strokeColor: S) -> some View {
        ZStack {
            self.fill(fillContent).opacity(opacity)
            self.stroke(strokeColor, lineWidth: strokeWidth)
        }
    }
}
