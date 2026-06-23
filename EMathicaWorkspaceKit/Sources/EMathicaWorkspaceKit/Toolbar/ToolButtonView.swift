import SwiftUI

public struct ToolButtonView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let tool: WorkspaceTool
    public let isSelected: Bool
    public let onToolAction: (WorkspaceToolAction) -> Void

    public var body: some View {
        Button {
            onToolAction(tool.action)
        } label: {
            toolIcon
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isSelected ? Color.white : unselectedForeground)
                .frame(width: 30, height: 30)
                .background {
                    if isSelected {
                        Capsule(style: .continuous).fill(Color.blue.opacity(0.92))
                    } else {
                        Capsule(style: .continuous).fill(Color.clear)
                    }
                }
        }
        .buttonStyle(.plain)
        .disabled(!tool.isEnabled)
        .opacity(tool.isEnabled ? 1.0 : 0.45)
        .accessibilityLabel(tool.accessibilityLabel ?? tool.title)
    }

    @ViewBuilder
    private var toolIcon: some View {
        switch tool.icon {
        case .system(let name):
            Image(systemName: name)

        case .asset(let name):
            Image(name)
                .renderingMode(.template)

        case .text(let text):
            Text(text)

        case .geometry(let glyph):
            GeometryToolIconView(glyph: glyph)
                .frame(width: 14, height: 14)
        }
    }

    private var unselectedForeground: Color {
        colorScheme == .dark ? Color.white.opacity(0.70) : Color.black.opacity(0.62)
    }
}
