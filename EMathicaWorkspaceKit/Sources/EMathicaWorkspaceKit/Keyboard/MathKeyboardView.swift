import EMathicaMathCore
import EMathicaMathInputCore
import EMathicaThemeKit
import SwiftUI

public struct MathKeyboardView: View {
    @Environment(\.colorScheme) private var colorScheme

    public var onKey: (KeyboardAction) -> Void
    public var style: MathKeyboardStyle

    @State private var selectedTab: MathKeyboardTab = .numbers

    public init(
        onKey: @escaping (KeyboardAction) -> Void,
        style: MathKeyboardStyle = .default
    ) {
        self.onKey = onKey
        self.style = style
    }

    public var body: some View {
        KeyboardGlassPanel(style: style) {
            VStack(spacing: MathKeyboardVisualMetrics.tabSpacing(for: style)) {
                MathKeyboardTabBar(selection: $selectedTab, style: style)

                VStack(spacing: MathKeyboardVisualMetrics.rowSpacing(for: style)) {
                    ForEach(selectedTab.rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: MathKeyboardVisualMetrics.keySpacing(for: style)) {
                            ForEach(selectedTab.rows[rowIndex]) { key in
                                MathKeyboardKey(
                                    key: key,
                                    colorScheme: colorScheme,
                                    style: style
                                ) {
                                    onKey(key.action)
                                }
                                .id("\(selectedTab.id)-\(key.id)")
                            }
                        }
                        .id("row-\(selectedTab.id)-\(rowIndex)")
                    }
                }
                .id("page-\(selectedTab.id)")
                .transaction { tx in
                    tx.animation = nil
                }
            }
            .padding(.top, MathKeyboardVisualMetrics.backplatePaddingTop(for: style))
            .padding(.horizontal, MathKeyboardVisualMetrics.backplatePaddingHorizontal(for: style))
            .padding(.bottom, MathKeyboardVisualMetrics.backplatePaddingBottom(for: style))
            .background {
                KeyboardKeysBackplate(colorScheme: colorScheme, style: style)
                    .padding(.vertical, -MathKeyboardVisualMetrics.backplateVisualBleedVertical(for: style))
                    .padding(.horizontal, -MathKeyboardVisualMetrics.backplateVisualBleedHorizontal(for: style))
            }
        }
        .transaction { tx in
            tx.animation = nil
        }
    }
}

private struct KeyboardKeysBackplate: View {
    let colorScheme: ColorScheme
    let style: MathKeyboardStyle

    var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius(for: style),
            style: .continuous
        )

        ZStack {
            shape
                .fill(backplateFill)

            shape
                .fill(.thinMaterial)
                .opacity(colorScheme == .dark ? style.panel.backplateMaterialDarkOpacity : style.panel.backplateMaterialLightOpacity)

            shape
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.10 : 0.14),
                            Color.clear,
                            Color.black.opacity(colorScheme == .dark ? 0.05 : 0.015)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .clipShape(shape)
        .overlay {
            shape
                .strokeBorder(
                    Color.white.opacity(
                        colorScheme == .dark ? style.panel.backplateStrokeDarkOpacity : style.panel.backplateStrokeLightOpacity
                    ),
                    lineWidth: MathKeyboardVisualMetrics.backplateStrokeLineWidth
                )
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(
                                colorScheme == .dark ? style.panel.backplateTopHighlightDarkOpacity : style.panel.backplateTopHighlightLightOpacity
                            ),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: MathKeyboardVisualMetrics.backplateTopHighlightHeight)
                .clipShape(shape)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(
                                colorScheme == .dark ? style.panel.backplateBottomShadeDarkOpacity : style.panel.backplateBottomShadeLightOpacity
                            )
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: MathKeyboardVisualMetrics.backplateBottomShadeHeight)
                .clipShape(shape)
                .allowsHitTesting(false)
        }
        .shadow(
            color: Color.black.opacity(
                colorScheme == .dark ? style.panel.backplateShadowDarkOpacity : style.panel.backplateShadowLightOpacity
            ),
            radius: colorScheme == .dark ? MathKeyboardVisualMetrics.backplateShadowRadiusDark : MathKeyboardVisualMetrics.backplateShadowRadiusLight,
            x: 0,
            y: colorScheme == .dark ? MathKeyboardVisualMetrics.backplateShadowYOffsetDark : MathKeyboardVisualMetrics.backplateShadowYOffsetLight
        )
        .allowsHitTesting(false)
    }

    private var backplateFill: Color {
        colorScheme == .dark
            ? Color.black.opacity(style.panel.backplateBackgroundDarkOpacity)
            : Color.white.opacity(style.panel.backplateBackgroundLightOpacity)
    }
}

private struct MathKeyboardTabBar: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var selection: MathKeyboardTab
    let style: MathKeyboardStyle

    var body: some View {
        HStack(spacing: MathKeyboardVisualMetrics.tabSpacing(for: style)) {
            ForEach(MathKeyboardTab.allCases) { tab in
                KeyboardTabButton(
                    title: tab.title,
                    isSelected: selection == tab,
                    colorScheme: colorScheme,
                    style: style
                ) {
                    var noAnimation = Transaction()
                    noAnimation.animation = nil
                    withTransaction(noAnimation) {
                        selection = tab
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .transaction { tx in
            tx.animation = nil
        }
    }
}

internal struct MathKeyboardKey: View, @preconcurrency Equatable {
    let key: KeyboardKey
    let colorScheme: ColorScheme
    let style: MathKeyboardStyle
    let action: () -> Void

    public static func == (lhs: MathKeyboardKey, rhs: MathKeyboardKey) -> Bool {
        lhs.key == rhs.key
    }

    var body: some View {
        GlassKeyButton(
            title: key.title,
            subtitle: key.subtitle,
            isAccent: key.isAccent,
            isTemplate: key.isTemplate,
            colorScheme: colorScheme,
            style: style
        ) {
            action()
        }
        .transaction { tx in
            tx.animation = nil
        }
    }
}

private struct KeyboardGlassPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    let style: MathKeyboardStyle
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(MathKeyboardVisualMetrics.shellPadding(for: style))
            .background {
                let shape = RoundedRectangle(
                    cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius(for: style),
                    style: .continuous
                )

                shape
                    .fill(
                        colorScheme == .dark
                            ? Color.black.opacity(style.panel.shellBackgroundDarkOpacity)
                            : Color.white.opacity(style.panel.shellBackgroundLightOpacity)
                    )
                    .overlay {
                        shape
                            .fill(.ultraThinMaterial)
                            .opacity(colorScheme == .dark ? style.panel.shellMaterialDarkOpacity : style.panel.shellMaterialLightOpacity)
                    }
                    .overlay {
                        shape
                            .stroke(
                                Color.white.opacity(
                                    colorScheme == .dark ? style.panel.shellStrokeDarkOpacity : style.panel.shellStrokeLightOpacity
                                ),
                                lineWidth: MathKeyboardVisualMetrics.strokeLineWidth
                            )
                    }
                    .overlay(alignment: .top) {
                        shape
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(
                                            colorScheme == .dark ? style.panel.shellTopGlowDarkOpacity : style.panel.shellTopGlowLightOpacity
                                        ),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: MathKeyboardVisualMetrics.shellTopGlowHeight)
                            .clipShape(shape)
                    }
                    .shadow(
                        color: Color.black.opacity(
                            colorScheme == .dark ? style.panel.shellShadowDarkOpacity : style.panel.shellShadowLightOpacity
                        ),
                        radius: colorScheme == .dark ? MathKeyboardVisualMetrics.shellShadowRadiusDark : MathKeyboardVisualMetrics.shellShadowRadiusLight,
                        x: 0,
                        y: colorScheme == .dark ? MathKeyboardVisualMetrics.shellShadowYOffsetDark : MathKeyboardVisualMetrics.shellShadowYOffsetLight
                    )
            }
    }
}

private struct KeyboardTabButton: View {
    let title: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let style: MathKeyboardStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                LiquidGlassKeyBackground(
                    role: isSelected ? .categoryActive : .category,
                    isPressed: false,
                    colorScheme: colorScheme,
                    style: style,
                    cornerRadius: CGFloat(style.tab.cornerRadius)
                )
                Text(title)
                    .font(.system(size: style.typography.tabFontSize, weight: .semibold))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: MathKeyboardVisualMetrics.tabHeight(for: style))
            .contentShape(RoundedRectangle(cornerRadius: CGFloat(style.tab.cornerRadius), style: .continuous))
        }
        .buttonStyle(.plain)
        .transaction { tx in
            tx.animation = nil
        }
    }

    private var labelColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(isSelected ? style.tab.selectedLabelDarkOpacity : style.tab.unselectedLabelDarkOpacity)
        }
        return Color.black.opacity(isSelected ? style.tab.selectedLabelLightOpacity : style.tab.unselectedLabelLightOpacity)
    }
}

private struct GlassKeyButton: View {
    let title: String
    let subtitle: String?
    let isAccent: Bool
    let isTemplate: Bool
    let colorScheme: ColorScheme
    let style: MathKeyboardStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                LiquidGlassKeyBackground(
                    role: isAccent ? .primary : .normal,
                    isPressed: false,
                    colorScheme: colorScheme,
                    style: style,
                    cornerRadius: CGFloat(style.key.cornerRadius)
                )

                VStack(spacing: 1) {
                    Text(title)
                        .font(
                            .system(
                                size: isTemplate ? style.typography.templatePrimaryFontSize : style.typography.primaryFontSize,
                                weight: .semibold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: style.typography.secondaryFontSize, weight: .medium, design: .rounded))
                            .foregroundStyle(subtitleColor)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: MathKeyboardVisualMetrics.keyMinHeight(for: style))
            .contentShape(RoundedRectangle(cornerRadius: CGFloat(style.key.cornerRadius), style: .continuous))
        }
        .buttonStyle(.plain)
        .transaction { tx in
            tx.animation = nil
        }
    }

    private var labelColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.94)
        }
        return Color.black.opacity(0.84)
    }

    private var subtitleColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.56)
        }
        return Color.black.opacity(0.56)
    }
}

private struct LiquidGlassKeyBackground: View {
    enum Role {
        case normal
        case category
        case categoryActive
        case primary
    }

    let role: Role
    let isPressed: Bool
    let colorScheme: ColorScheme
    let style: MathKeyboardStyle
    var cornerRadius: CGFloat = 10

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(baseFill)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(resolvedRole.materialOpacity)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(resolvedRole.highlightOpacity),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: MathKeyboardVisualMetrics.strokeLineWidth)
            }
            .shadow(
                color: Color.black.opacity(
                    colorScheme == .dark ? style.key.shadowDarkOpacity : style.key.shadowLightOpacity
                ),
                radius: MathKeyboardVisualMetrics.keyShadowRadius,
                x: 0,
                y: MathKeyboardVisualMetrics.keyShadowYOffset
            )
            .scaleEffect(isPressed ? 0.985 : 1.0)
    }

    private var baseFill: Color {
        switch visualRole {
        case .normal, .category:
            return Color.white.opacity(resolvedRole.fillOpacity)
        case .categoryActive, .primary:
            return Color.accentColor.opacity(resolvedRole.fillOpacity)
        }
    }

    private var strokeColor: Color {
        Color.white.opacity(resolvedRole.strokeOpacity)
    }

    private var visualRole: MathKeyboardSurfaceRole {
        switch role {
        case .normal:
            return .normal
        case .category:
            return .category
        case .categoryActive:
            return .categoryActive
        case .primary:
            return .primary
        }
    }

    private var resolvedRole: MathKeyboardResolvedKeyRole {
        MathKeyboardVisualMetrics.keyRole(for: visualRole, style: style, colorScheme: colorScheme)
    }
}
