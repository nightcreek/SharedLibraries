import SwiftUI

public enum LiquidGlassButtonKind: Hashable {
    case primary
    case secondary
}

public struct LiquidGlassButton: View {
    @Environment(\.colorScheme) private var colorScheme

    public let title: String
    public let systemImage: String?
    public let kind: LiquidGlassButtonKind
    public let action: () -> Void

    public init(_ title: String, systemImage: String? = nil, kind: LiquidGlassButtonKind = .secondary, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.kind = kind
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .foregroundStyle(foreground)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(border, lineWidth: 1)
        }
        .shadow(color: shadow, radius: 16, x: 0, y: 10)
    }

    private var foreground: Color {
        switch kind {
        case .primary:
            return .white
        case .secondary:
            return colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.88)
        }
    }

    private var border: Color {
        switch kind {
        case .primary:
            return Color.white.opacity(colorScheme == .dark ? 0.14 : 0.18)
        case .secondary:
            return colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.08)
        }
    }

    private var shadow: Color {
        Color.black.opacity(colorScheme == .dark ? 0.35 : 0.12)
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .primary:
            if #available(iOS 26.0, macOS 16.0, *) {
                Color.clear
                    .glassEffect(.regular.tint(Color.blue.opacity(0.95)).interactive(), in: .rect(cornerRadius: 18))
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.blue.opacity(colorScheme == .dark ? 0.95 : 0.92))
            }
        case .secondary:
            if #available(iOS 26.0, macOS 16.0, *) {
                Color.clear
                    .glassEffect(.regular.tint(Color.blue.opacity(colorScheme == .dark ? 0.25 : 0.12)).interactive(), in: .rect(cornerRadius: 18))
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.thinMaterial)
            }
        }
    }
}
