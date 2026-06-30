import EMathicaThemeKit
import EMathicaWorkspaceKit
import SwiftUI

struct HomeModuleDisplayItem: Identifiable, Hashable {
    var id: String
    var title: String
    var subtitle: String
    var iconName: String
    var accentToken: ColorToken

    init(
        id: String,
        title: String,
        subtitle: String,
        iconName: String,
        accentToken: ColorToken
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconName = iconName
        self.accentToken = accentToken
    }
}

struct CalculatorModuleSidebarView: View {
    @Environment(\.colorScheme) private var colorScheme

    let modules: [HomeModuleDisplayItem]
    let selectedModuleID: String
    let onSelect: (String) -> Void

    init(
        modules: [HomeModuleDisplayItem],
        selectedModuleID: String,
        onSelect: @escaping (String) -> Void
    ) {
        self.modules = modules
        self.selectedModuleID = selectedModuleID
        self.onSelect = onSelect
    }

    var body: some View {
        LiquidGlassPanel {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(modules) { module in
                    Button {
                        onSelect(module.id)
                    } label: {
                        HStack(spacing: 12) {
                            ModuleIconView(
                                iconName: module.iconName,
                                accent: module.accentToken.resolvedColor()
                            )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(module.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(primaryText)
                                    .lineLimit(1)

                                Text(module.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(selectionBackground(for: module))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(width: 260)
    }

    private var primaryText: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : Color.black.opacity(0.86)
    }

    @ViewBuilder
    private func selectionBackground(for module: HomeModuleDisplayItem) -> some View {
        if selectedModuleID == module.id {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.blue.opacity(colorScheme == .dark ? 0.35 : 0.22), lineWidth: 1)
                }
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.clear)
        }
    }
}
