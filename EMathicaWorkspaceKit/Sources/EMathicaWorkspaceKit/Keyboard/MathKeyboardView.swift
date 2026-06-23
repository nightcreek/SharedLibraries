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
                    print("[KeyboardTab] tapped \(tab.id)")
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
            print("[KeyTap] key.id = \(key.id)")
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

public enum MathKeyboardVisualMetrics {
    public static let backplateCornerRadius: CGFloat = 20
    public static let backplatePaddingTop: CGFloat = 12
    public static let backplatePaddingHorizontal: CGFloat = 9
    public static let backplatePaddingBottom: CGFloat = 10
    public static let backplateVisualBleedVertical: CGFloat = 5
    public static let backplateVisualBleedHorizontal: CGFloat = 3
    public static let keysBackplateDarkOpacity: Double = 0.32
    public static let keysBackplateLightOpacity: Double = 0.22
    public static let keysBackplateMaterialDarkOpacity: Double = 0.46
    public static let keysBackplateMaterialLightOpacity: Double = 0.54
    public static let keysBackplateStrokeDarkOpacity: Double = 0.24
    public static let keysBackplateStrokeLightOpacity: Double = 0.18
    public static let keysBackplateTopHighlightDarkOpacity: Double = 0.11
    public static let keysBackplateTopHighlightLightOpacity: Double = 0.14
    public static let keysBackplateBottomShadeDarkOpacity: Double = 0.08
    public static let keysBackplateBottomShadeLightOpacity: Double = 0.03
    public static let backplateTopHighlightHeight: CGFloat = 1
    public static let backplateBottomShadeHeight: CGFloat = 3
    public static let keysBackplateShadowDarkOpacity: Double = 0.14
    public static let keysBackplateShadowLightOpacity: Double = 0.06
    public static let keyDarkOpacity: Double = 0.05
    public static let keyLightOpacity: Double = 0.22
    public static let categoryKeyDarkOpacity: Double = 0.04
    public static let categoryKeyLightOpacity: Double = 0.20
    public static let categoryActiveDarkOpacity: Double = 0.24
    public static let categoryActiveLightOpacity: Double = 0.24
    public static let accentKeyDarkOpacity: Double = 0.26
    public static let accentKeyLightOpacity: Double = 0.24
    public static let keyBorderDarkOpacity: Double = 0.16
    public static let keyBorderLightOpacity: Double = 0.24
}

public struct KeyboardKey: Identifiable, Hashable, Equatable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var action: KeyboardAction
    public var isTemplate: Bool
    public var isAccent: Bool

    public static func text(_ value: String) -> KeyboardKey {
        KeyboardKey(id: "text:\(value)", title: value, subtitle: nil, action: .insertCharacter(value), isTemplate: false, isAccent: false)
    }

    public static func symbol(_ title: String, raw: String) -> KeyboardKey {
        KeyboardKey(id: "symbol:\(raw)", title: title, subtitle: nil, action: .insertSymbol(raw), isTemplate: false, isAccent: false)
    }

    public static func op(_ title: String, raw: String, accent: Bool = false) -> KeyboardKey {
        KeyboardKey(id: "op:\(raw):\(title)", title: title, subtitle: nil, action: .insertOperator(raw), isTemplate: false, isAccent: accent)
    }

    public static func template(_ title: String, subtitle: String, kind: TemplateKind, accent: Bool = false) -> KeyboardKey {
        KeyboardKey(id: "tpl:\(title)", title: title, subtitle: subtitle, action: .insertTemplate(kind), isTemplate: true, isAccent: accent)
    }

    public static func function(_ title: String) -> KeyboardKey {
        KeyboardKey(id: "fn:\(title)", title: title, subtitle: nil, action: .insertFunction(title), isTemplate: false, isAccent: false)
    }

    public static func command(_ title: String, action: KeyboardAction, accent: Bool = false) -> KeyboardKey {
        KeyboardKey(id: "cmd:\(title)", title: title, subtitle: nil, action: action, isTemplate: false, isAccent: accent)
    }
}

public enum MathKeyboardTab: String, CaseIterable, Identifiable {
    case numbers
    case functions
    case alphabet
    case symbols

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .numbers: return "123"
        case .functions: return "f(x)"
        case .alphabet: return "ABC"
        case .symbols: return "符号"
        }
    }

    public var rows: [[KeyboardKey]] {
        switch self {
        case .numbers:
            return [
                [.text("x"), .text("y"), .symbol("π", raw: "\\pi"), .text("e"), .text("7"), .text("8"), .text("9"), .op("×", raw: "*"), .op("÷", raw: "/")],
                [.template("x²", subtitle: "上标", kind: .superscript), .template("xʸ", subtitle: "指数", kind: .superscript), .template("√□", subtitle: "根号", kind: .sqrt), .template("|□|", subtitle: "绝对值", kind: .absoluteValue), .text("4"), .text("5"), .text("6"), .op("+", raw: "+"), .op("-", raw: "-")],
                [.op("<", raw: "<"), .op(">", raw: ">"), .op("≤", raw: "\\leq"), .op("≥", raw: "\\geq"), .text("1"), .text("2"), .text("3"), .op("=", raw: "=", accent: true), .command("⌫", action: .deleteBackward)],
                [.function("sin"), .function("cos"), .function("tan"), .function("log"), .text("0"), .text("."), .command("←", action: .moveLeft), .command("→", action: .moveRight), .command("↵", action: .submit, accent: true)]
            ]
        case .functions:
            return [
                [.function("sin"), .function("cos"), .function("tan"), .function("ln"), .function("log"), .function("exp"), .template("|□|", subtitle: "abs", kind: .absoluteValue), .template("√□", subtitle: "根号", kind: .sqrt), .template("□⁄□", subtitle: "分数", kind: .fraction)],
                [.template("xʸ", subtitle: "上标", kind: .superscript), .template("xₙ", subtitle: "下标", kind: .subscriptTemplate), .template("x(t),y(t)", subtitle: "参数", kind: .parametricEquation2D), .template("分段", subtitle: "cases", kind: .piecewise(rows: 2)), .template("(□)", subtitle: "括号", kind: .parentheses), .text("("), .text(")"), .op("+", raw: "+"), .op("-", raw: "-")],
                [.text("x"), .text("y"), .text("t"), .symbol("π", raw: "\\pi"), .text("e"), .command("←", action: .moveLeft), .command("→", action: .moveRight), .command("⌫", action: .deleteBackward), .command("↵", action: .submit, accent: true)]
            ]
        case .alphabet:
            return [
                [.text("a"), .text("b"), .text("c"), .text("d"), .text("n"), .text("r"), .text("h"), .text("k"), .text("m")],
                [.text("p"), .text("q"), .text("u"), .text("v"), .text("A"), .text("B"), .text("C"), .text("D"), .text("E")],
                [.text("f"), .text("g"), .text("i"), .text("j"), .text("l"), .text("o"), .text("s"), .text("w"), .text("z")],
                [.command("←", action: .moveLeft), .command("→", action: .moveRight), .text(","), .text("."), .text("("), .text(")"), .op("=", raw: "="), .command("⌫", action: .deleteBackward), .command("↵", action: .submit, accent: true)]
            ]
        case .symbols:
            return [
                [.op("<", raw: "<"), .op(">", raw: ">"), .op("≤", raw: "\\leq"), .op("≥", raw: "\\geq"), .op("≠", raw: "\\neq"), .text("("), .text(")"), .text("["), .text("]")],
                [.text("|"), .text("{"), .text("}"), .op("+", raw: "+"), .op("-", raw: "-"), .op("×", raw: "*"), .op("÷", raw: "/"), .op("=", raw: "="), .text(",")],
                [.symbol("θ", raw: "\\theta"), .symbol("α", raw: "\\alpha"), .symbol("β", raw: "\\beta"), .symbol("∞", raw: "\\infty"), .symbol("∈", raw: "\\in"), .symbol("∉", raw: "\\notin"), .symbol("∅", raw: "\\emptyset"), .command("⌫", action: .deleteBackward), .command("↵", action: .submit, accent: true)]
            ]
        }
    }
}
