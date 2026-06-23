import EMathicaThemeKit
import SwiftUI

public struct ToolGroupCapsuleView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let group: WorkspaceToolGroup
    public let selectedToolID: String?
    public let onToolAction: (WorkspaceToolAction) -> Void

    public var body: some View {
        let displayedTool = group.displayedTool(for: selectedToolID)
        let isGroupActive = group.selectedTool(for: selectedToolID) != nil

        LiquidGlassPanel(theme: capsuleTheme) {
            Menu {
                ForEach(group.tools) { tool in
                    Button {
                        onToolAction(tool.action)
                    } label: {
                        HStack(spacing: 8) {
                            toolIcon(for: tool)
                            Text(tool.title)
                            if tool.id == selectedToolID {
                                Spacer(minLength: 6)
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    .disabled(!tool.isEnabled)
                }
            } label: {
                HStack(spacing: 8) {
                    if let displayedTool {
                        toolIcon(for: displayedTool)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(groupForeground)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(groupForeground.opacity(0.82))
                }
                .frame(minWidth: 44, minHeight: 30)
                .padding(.horizontal, 8)
                .contentShape(Rectangle())
                .background {
                    Capsule(style: .continuous)
                        .fill(isGroupActive ? Color.accentColor.opacity(colorScheme == .dark ? 0.26 : 0.18) : Color.clear)
                }
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .accessibilityLabel(group.title)
        }
    }

    private var capsuleTheme: WorkspaceTheme {
        var t = WorkspaceTheme.sidePanel
        t.panelCornerRadius = 999
        t.panelPadding = 6
        t.lightPanelOpacity = ToolGroupCapsuleVisualMetrics.lightPanelOpacity
        t.darkPanelOpacity = ToolGroupCapsuleVisualMetrics.darkPanelOpacity
        t.lightStrokeOpacity = ToolGroupCapsuleVisualMetrics.lightStrokeOpacity
        t.darkStrokeOpacity = ToolGroupCapsuleVisualMetrics.darkStrokeOpacity
        return t
    }

    @ViewBuilder
    private func toolIcon(for tool: WorkspaceTool) -> some View {
        switch tool.icon {
        case .system(let name):
            Image(systemName: name)

        case .asset(let name):
            Image(name)
                .renderingMode(.template)

        case .text(let text):
            Text(text)
                .font(.system(size: 11, weight: .semibold))

        case .geometry(let glyph):
            GeometryToolIconView(glyph: glyph)
                .frame(width: 15, height: 15)
        }
    }

    private var groupForeground: Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : Color.black.opacity(0.78)
    }
}

public enum ToolGroupCapsuleVisualMetrics {
    public static let lightPanelOpacity: Double = 0.22
    public static let darkPanelOpacity: Double = 0.18
    public static let lightStrokeOpacity: Double = 0.10
    public static let darkStrokeOpacity: Double = 0.12
}
