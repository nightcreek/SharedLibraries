import EMathicaMathInputCore
import EMathicaThemeKit
import SwiftUI

public struct MathInputKeyboardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public let layout: MathKeyboardLayout
    public let style: MathKeyboardStyle
    private let onIntentHandler: (MathKeyboardIntent) -> Void
    @State private var surfaceModel: MathInputKeyboardSurfaceModel

    public init(
        layout: MathKeyboardLayout = MathKeyboardLayouts.standard,
        style: MathKeyboardStyle = .default,
        onIntent: @escaping (MathKeyboardIntent) -> Void
    ) {
        self.layout = layout
        self.style = style
        self.onIntentHandler = onIntent
        _surfaceModel = State(initialValue: MathInputKeyboardSurfaceModel(layout: layout))
    }

    public init(
        layout: MathKeyboardLayout = MathKeyboardLayouts.standard,
        style: MathKeyboardStyle = .default,
        onAction: @escaping (KeyboardAction) -> Void
    ) {
        self.init(layout: layout, style: style) { intent in
            guard let action = intent.keyboardAction else { return }
            onAction(action)
        }
    }

    public var body: some View {
        let currentPanel = surfaceModel.visiblePanel

        VStack(spacing: style.spacing.tabSpacing) {
            HStack(spacing: style.spacing.tabSpacing) {
                ForEach(layout.panels) { panel in
                    Button {
                        surfaceModel.select(panelID: panel.id)
                    } label: {
                        Text(panel.title)
                            .font(.system(size: style.typography.tabFontSize, weight: .semibold, design: .rounded))
                            .foregroundStyle(
                                MathInputKeyboardStyleBridge.tabLabelColor(
                                    style: style,
                                    isSelected: surfaceModel.selectedPanelID == panel.id,
                                    colorScheme: colorScheme
                                )
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: style.spacing.tabHeight)
                            .background {
                                MathInputKeyboardStyleBridge.tabBackground(
                                    style: style,
                                    isSelected: surfaceModel.selectedPanelID == panel.id,
                                    colorScheme: colorScheme
                                )
                            }
                            .contentShape(RoundedRectangle(cornerRadius: style.tab.cornerRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if let currentPanel {
                MathInputKeyboardPanelView(
                    panel: currentPanel,
                    style: style,
                    onKeyPress: { key in
                        surfaceModel.handle(key, forwarding: onIntentHandler)
                    }
                )
                .background {
                    RoundedRectangle(cornerRadius: style.panel.cornerRadius, style: .continuous)
                        .fill(
                            colorScheme == .dark
                                ? Color.black.opacity(style.panel.backplateBackgroundDarkOpacity)
                                : Color.white.opacity(style.panel.backplateBackgroundLightOpacity)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: style.panel.cornerRadius, style: .continuous)
                                .fill(.thinMaterial)
                                .opacity(
                                    colorScheme == .dark
                                        ? style.panel.backplateMaterialDarkOpacity
                                        : style.panel.backplateMaterialLightOpacity
                                )
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: style.panel.cornerRadius, style: .continuous)
                                .stroke(
                                    Color.white.opacity(
                                        colorScheme == .dark
                                            ? style.panel.backplateStrokeDarkOpacity
                                            : style.panel.backplateStrokeLightOpacity
                                    ),
                                    lineWidth: 0.8
                                )
                        }
                }
            }
        }
        .padding(style.spacing.shellPadding)
        .background {
            MathInputKeyboardStyleBridge.panelBackground(style: style, colorScheme: colorScheme)
        }
    }
}
