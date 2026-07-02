import EMathicaMathInputCore
import EMathicaThemeKit
import EMathicaMathCore
import SwiftUI

public struct MathKeyboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    public var onKey: (KeyboardAction) -> Void

    @State private var selectedTab: MathKeyboardTab = .numbers

    public var body: some View {
        KeyboardGlassPanel {
            VStack(spacing: 8) {
                MathKeyboardTabBar(selection: $selectedTab)

                VStack(spacing: 7) {
                    ForEach(selectedTab.rows.indices, id: \.self) { rowIndex in
                        HStack(spacing: 7) {
                            ForEach(selectedTab.rows[rowIndex]) { key in
                                MathKeyboardKey(key: key, colorScheme: colorScheme) {
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
            .padding(.top, MathKeyboardVisualMetrics.backplatePaddingTop)
            .padding(.horizontal, MathKeyboardVisualMetrics.backplatePaddingHorizontal)
            .padding(.bottom, MathKeyboardVisualMetrics.backplatePaddingBottom)
            .background {
                KeyboardKeysBackplate(colorScheme: colorScheme)
                    .padding(.vertical, -MathKeyboardVisualMetrics.backplateVisualBleedVertical)
                    .padding(.horizontal, -MathKeyboardVisualMetrics.backplateVisualBleedHorizontal)
            }
        }
        .transaction { tx in
            tx.animation = nil
        }
    }
}

private struct KeyboardKeysBackplate: View {
    public let colorScheme: ColorScheme

    public var body: some View {
        let shape = RoundedRectangle(
            cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius,
            style: .continuous
        )

        ZStack {
            shape
                .fill(backplateFill)

            shape
                .fill(.thinMaterial)
                .opacity(
                    colorScheme == .dark
                        ? MathKeyboardVisualMetrics.keysBackplateMaterialDarkOpacity
                        : MathKeyboardVisualMetrics.keysBackplateMaterialLightOpacity
                )

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
                        colorScheme == .dark
                            ? MathKeyboardVisualMetrics.keysBackplateStrokeDarkOpacity
                            : MathKeyboardVisualMetrics.keysBackplateStrokeLightOpacity
                    ),
                    lineWidth: 0.8
                )
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(
                                colorScheme == .dark
                                    ? MathKeyboardVisualMetrics.keysBackplateTopHighlightDarkOpacity
                                    : MathKeyboardVisualMetrics.keysBackplateTopHighlightLightOpacity
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
                                colorScheme == .dark
                                    ? MathKeyboardVisualMetrics.keysBackplateBottomShadeDarkOpacity
                                    : MathKeyboardVisualMetrics.keysBackplateBottomShadeLightOpacity
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
                    colorScheme == .dark
                        ? MathKeyboardVisualMetrics.keysBackplateShadowDarkOpacity
                        : MathKeyboardVisualMetrics.keysBackplateShadowLightOpacity
                ),
                radius: colorScheme == .dark ? 18 : 14,
                x: 0,
                y: colorScheme == .dark ? 5 : 4
            )
            .allowsHitTesting(false)
    }

    private var backplateFill: Color {
        colorScheme == .dark
            ? Color.black.opacity(MathKeyboardVisualMetrics.keysBackplateDarkOpacity)
            : Color.white.opacity(MathKeyboardVisualMetrics.keysBackplateLightOpacity)
    }
}

private struct MathKeyboardTabBar: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var selection: MathKeyboardTab

    public var body: some View {
        HStack(spacing: 6) {
            ForEach(MathKeyboardTab.allCases) { tab in
                KeyboardTabButton(
                    title: tab.title,
                    isSelected: selection == tab,
                    colorScheme: colorScheme
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
    public let key: KeyboardKey
    public let colorScheme: ColorScheme
    public let action: () -> Void

    public static func == (lhs: MathKeyboardKey, rhs: MathKeyboardKey) -> Bool {
        lhs.key == rhs.key
    }

    public var body: some View {
        GlassKeyButton(
            title: key.title,
            subtitle: key.subtitle,
                isAccent: key.isAccent,
                isTemplate: key.isTemplate,
                colorScheme: colorScheme
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
    @ViewBuilder var content: Content

    public var body: some View {
        content
            .padding(8)
            .background {
                RoundedRectangle(cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius, style: .continuous)
                    .fill(
                        colorScheme == .dark
                            ? Color.black.opacity(0.008)
                            : Color.white.opacity(0.018)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(colorScheme == .dark ? 0.22 : 0.28)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius, style: .continuous)
                            .stroke(
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.10),
                                lineWidth: 0.7
                            )
                    }
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.05 : 0.09),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: 8)
                            .clipShape(RoundedRectangle(cornerRadius: MathKeyboardVisualMetrics.backplateCornerRadius, style: .continuous))
                    }
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.025 : 0.02),
                        radius: colorScheme == .dark ? 8 : 7,
                        x: 0,
                        y: colorScheme == .dark ? 2 : 1
                    )
            }
    }
}

private struct KeyboardTabButton: View {
    public let title: String
    public let isSelected: Bool
    public let colorScheme: ColorScheme
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            ZStack {
                LiquidGlassKeyBackground(
                    role: isSelected ? .categoryActive : .category,
                    isPressed: false,
                    colorScheme: colorScheme,
                    cornerRadius: 12
                )
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .transaction { tx in
            tx.animation = nil
        }
    }

    private var labelColor: Color {
        if colorScheme == .dark {
            return Color.white.opacity(0.92)
        }
        return Color.black.opacity(0.82)
    }
}

private struct GlassKeyButton: View {
    public let title: String
    public let subtitle: String?
    public let isAccent: Bool
    public let isTemplate: Bool
    public let colorScheme: ColorScheme
    public let action: () -> Void

    public var body: some View {
        Button(action: action) {
            ZStack {
                LiquidGlassKeyBackground(
                    role: isAccent ? .primary : .normal,
                    isPressed: false,
                    colorScheme: colorScheme
                )

                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: isTemplate ? 13 : 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(labelColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 8.5, weight: .medium, design: .rounded))
                            .foregroundStyle(subtitleColor)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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
    public enum Role {
        case normal
        case category
        case categoryActive
        case primary
    }

    public let role: Role
    public let isPressed: Bool
    public let colorScheme: ColorScheme
    public var cornerRadius: CGFloat = 10

    public var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(baseFill)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(materialOpacity)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(topHighlightOpacity),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 0.7)
            }
            .shadow(color: Color.black.opacity(shadowOpacity), radius: 4, x: 0, y: 1)
            .scaleEffect(isPressed ? 0.985 : 1.0)
    }

    private var baseFill: Color {
        switch role {
        case .normal:
            return Color.white.opacity(colorScheme == .dark ? MathKeyboardVisualMetrics.keyDarkOpacity : MathKeyboardVisualMetrics.keyLightOpacity)
        case .category:
            return Color.white.opacity(colorScheme == .dark ? MathKeyboardVisualMetrics.categoryKeyDarkOpacity : MathKeyboardVisualMetrics.categoryKeyLightOpacity)
        case .categoryActive:
            return Color.accentColor.opacity(colorScheme == .dark ? MathKeyboardVisualMetrics.categoryActiveDarkOpacity : MathKeyboardVisualMetrics.categoryActiveLightOpacity)
        case .primary:
            return Color.accentColor.opacity(colorScheme == .dark ? MathKeyboardVisualMetrics.accentKeyDarkOpacity : MathKeyboardVisualMetrics.accentKeyLightOpacity)
        }
    }

    private var strokeColor: Color {
        let opacity: Double
        switch role {
        case .normal:
            opacity = colorScheme == .dark ? MathKeyboardVisualMetrics.keyBorderDarkOpacity : MathKeyboardVisualMetrics.keyBorderLightOpacity
        case .category:
            opacity = colorScheme == .dark ? 0.13 : 0.26
        case .categoryActive:
            opacity = colorScheme == .dark ? 0.18 : 0.34
        case .primary:
            opacity = colorScheme == .dark ? 0.19 : 0.36
        }
        return Color.white.opacity(opacity)
    }

    private var materialOpacity: Double {
        switch role {
        case .normal:
            return colorScheme == .dark ? 0.12 : 0.18
        case .category:
            return colorScheme == .dark ? 0.10 : 0.16
        case .categoryActive:
            return colorScheme == .dark ? 0.12 : 0.16
        case .primary:
            return colorScheme == .dark ? 0.14 : 0.18
        }
    }

    private var topHighlightOpacity: Double {
        switch role {
        case .normal: return colorScheme == .dark ? 0.12 : 0.10
        case .category: return colorScheme == .dark ? 0.10 : 0.09
        case .categoryActive: return colorScheme == .dark ? 0.14 : 0.12
        case .primary: return colorScheme == .dark ? 0.14 : 0.12
        }
    }

    private var shadowOpacity: Double {
        colorScheme == .dark ? 0.08 : 0.06
    }
}
