import SwiftUI

public struct LiquidGlassInputBar<Content: View>: View {
    public let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        LiquidGlassPanel(theme: theme) {
            content
        }
    }

    private var theme: WorkspaceTheme {
        var t = WorkspaceTheme()
        t.panelCornerRadius = 26
        t.panelPadding = 10
        return t
    }
}
