import SwiftUI

public struct GlassPanel<Content: View>: View {
    public var cornerRadius: CGFloat = 20
    public var theme: WorkspaceTheme = WorkspaceTheme()
    public var contentPadding: CGFloat? = nil
    @ViewBuilder var content: Content

    public init(cornerRadius: CGFloat = 20, theme: WorkspaceTheme = WorkspaceTheme(), contentPadding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.theme = theme
        self.contentPadding = contentPadding
        self.content = content()
    }

    public var body: some View {
        var appliedTheme = theme
        if let contentPadding {
            appliedTheme.panelPadding = contentPadding
        }
        return LiquidGlassPanel(theme: appliedTheme) {
            content
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

public struct GlassButton<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    public var isSelected: Bool = false
    public var cornerRadius: CGFloat = 12
    public var action: () -> Void
    @ViewBuilder var content: Content

    public var body: some View {
        Button(action: action) {
            content
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.plain)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.clear)
                .overlay { background }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.10 : 0.06), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var background: some View {
        if isSelected {
            if #available(iOS 26.0, macOS 16.0, *) {
                Color.clear
                    .glassEffect(.regular.tint(Color.blue.opacity(colorScheme == .dark ? 0.28 : 0.18)).interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                Color.blue.opacity(colorScheme == .dark ? 0.24 : 0.14)
            }
        } else if #available(iOS 26.0, macOS 16.0, *) {
            Color.clear
                .glassEffect(.regular.tint(Color.white.opacity(colorScheme == .dark ? 0.02 : 0.05)).interactive(), in: .rect(cornerRadius: cornerRadius))
        } else {
            Color.clear
                .background(.thinMaterial)
        }
    }

    private var border: Color {
        if isSelected {
            return Color.white.opacity(colorScheme == .dark ? 0.22 : 0.42)
        }
        return Color.white.opacity(colorScheme == .dark ? 0.12 : 0.30)
    }
}

public struct GlassSegmentedControl<Item: Hashable>: View {
    public var items: [Item]
    public var title: (Item) -> String
    @Binding var selection: Item

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(items, id: \.self) { item in
                GlassButton(isSelected: selection == item) {
                    selection = item
                } content: {
                    Text(title(item))
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                }
            }
        }
    }
}
