import SwiftUI

public struct LiquidGlassPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    public let theme: WorkspaceTheme
    public let content: Content

    public init(theme: WorkspaceTheme = WorkspaceTheme(), @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    public var body: some View {
        content
            .padding(theme.panelPadding)
            .background(panelBackground)
            .clipShape(RoundedRectangle(cornerRadius: theme.panelCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: theme.panelCornerRadius, style: .continuous)
                    .stroke(theme.subtleStroke(for: colorScheme), lineWidth: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: theme.panelCornerRadius, style: .continuous)
                    .fill(highlight)
                    .blendMode(colorScheme == .dark ? .screen : .softLight)
                    .allowsHitTesting(false)
            }
            .shadow(color: theme.shadowColor(for: colorScheme), radius: 12, x: 0, y: 6)
    }

    private var highlight: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color.white.opacity(0.10), Color.white.opacity(0.02), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        return LinearGradient(
            colors: [Color.white.opacity(0.55), Color.white.opacity(0.12), Color.clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    @ViewBuilder
    private var panelBackground: some View {
        if #available(iOS 26.0, macOS 16.0, *) {
            Color.clear
                .glassEffect(.regular.tint(theme.panelTint(for: colorScheme)).interactive(), in: .rect(cornerRadius: theme.panelCornerRadius))
        } else {
            RoundedRectangle(cornerRadius: theme.panelCornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: theme.panelCornerRadius, style: .continuous)
                        .fill(theme.panelTint(for: colorScheme))
                }
        }
    }
}
