import SwiftUI

public struct FloatingPanelModifier: ViewModifier {
    public var cornerRadius: CGFloat = 24

    public func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

public extension View {
    public func floatingPanel(cornerRadius: CGFloat = 24) -> some View {
        modifier(FloatingPanelModifier(cornerRadius: cornerRadius))
    }
}
