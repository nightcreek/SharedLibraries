import SwiftUI

public struct LiquidGlassIconButton: View {
    @Environment(\.colorScheme) private var colorScheme

    public var systemName: String
    public var accessibilityLabel: String
    public var action: () -> Void

    public init(systemName: String, accessibilityLabel: String, action: @escaping () -> Void) {
        self.systemName = systemName
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(colorScheme == .dark ? Color.white.opacity(0.88) : Color.black.opacity(0.78))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .background(background)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.08 : 0.05), radius: 10, x: 0, y: 5)
    }

    @ViewBuilder
    private var background: some View {
        if #available(iOS 26.0, macOS 16.0, *) {
            Color.clear
                .glassEffect(.regular.tint(Color.white.opacity(colorScheme == .dark ? 0.03 : 0.06)).interactive(), in: .circle)
        } else {
            Circle()
                .fill(.ultraThinMaterial)
        }
    }
}
