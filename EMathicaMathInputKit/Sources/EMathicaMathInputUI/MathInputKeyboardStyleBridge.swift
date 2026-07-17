import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import EMathicaMathInputCore
import EMathicaThemeKit
import SwiftUI

enum MathInputKeyboardKeyVisualRole {
    case standard
    case template
    case accent
    case system
}

enum MathInputKeyboardLabelPresentation: Equatable {
    case formulaMarkup(String)
    case systemImage(String)
    case plainText(String)
    case debugFallback(keyID: String, markup: String, message: String, fallback: String)
}

enum MathInputKeyboardStyleBridge {
    static func keyVisualRole(for key: MathKeyboardKey) -> MathInputKeyboardKeyVisualRole {
        if isAccent(key) {
            return .accent
        }

        switch key.label {
        case .systemIcon:
            return .system
        case .formula:
            return .template
        case .symbol, .text:
            return .standard
        }
    }

    static func titleColor(
        for role: MathInputKeyboardKeyVisualRole,
        colorScheme: ColorScheme
    ) -> Color {
        switch role {
        case .accent:
            return colorScheme == .dark ? Color.white.opacity(0.98) : Color.white.opacity(0.98)
        case .standard, .template, .system:
            return colorScheme == .dark ? Color.white.opacity(0.94) : Color.black.opacity(0.84)
        }
    }

    static func keyBackground(
        style: MathKeyboardStyle,
        role: MathInputKeyboardKeyVisualRole,
        colorScheme: ColorScheme,
        isPressed: Bool
    ) -> some View {
        let fillOpacity: Double
        let strokeOpacity: Double
        let materialOpacity: Double
        let highlightOpacity: Double

        switch role {
        case .standard, .system:
            fillOpacity = colorScheme == .dark ? style.key.normalBackgroundDarkOpacity : style.key.normalBackgroundLightOpacity
            strokeOpacity = colorScheme == .dark ? style.key.normalStrokeDarkOpacity : style.key.normalStrokeLightOpacity
            materialOpacity = colorScheme == .dark ? style.key.normalMaterialDarkOpacity : style.key.normalMaterialLightOpacity
            highlightOpacity = colorScheme == .dark ? style.key.normalHighlightDarkOpacity : style.key.normalHighlightLightOpacity
        case .template:
            fillOpacity = colorScheme == .dark ? style.key.categoryBackgroundDarkOpacity : style.key.categoryBackgroundLightOpacity
            strokeOpacity = colorScheme == .dark ? style.key.categoryStrokeDarkOpacity : style.key.categoryStrokeLightOpacity
            materialOpacity = colorScheme == .dark ? style.key.categoryMaterialDarkOpacity : style.key.categoryMaterialLightOpacity
            highlightOpacity = colorScheme == .dark ? style.key.categoryHighlightDarkOpacity : style.key.categoryHighlightLightOpacity
        case .accent:
            fillOpacity = colorScheme == .dark ? style.key.accentBackgroundDarkOpacity : style.key.accentBackgroundLightOpacity
            strokeOpacity = colorScheme == .dark ? style.key.accentStrokeDarkOpacity : style.key.accentStrokeLightOpacity
            materialOpacity = colorScheme == .dark ? style.key.accentMaterialDarkOpacity : style.key.accentMaterialLightOpacity
            highlightOpacity = colorScheme == .dark ? style.key.accentHighlightDarkOpacity : style.key.accentHighlightLightOpacity
        }

        let baseColor: Color = role == .accent ? .accentColor : .white
        let shape = RoundedRectangle(cornerRadius: style.key.cornerRadius, style: .continuous)

        return shape
            .fill(baseColor.opacity(fillOpacity))
            .overlay {
                shape
                    .fill(.ultraThinMaterial)
                    .opacity(materialOpacity)
            }
            .overlay {
                shape
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: 0.7)
            }
            .overlay {
                shape
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(highlightOpacity),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? style.key.shadowDarkOpacity : style.key.shadowLightOpacity),
                radius: 4,
                x: 0,
                y: 1
            )
            .scaleEffect(isPressed ? 0.985 : 1.0)
    }

    static func panelBackground(style: MathKeyboardStyle, colorScheme: ColorScheme) -> some View {
        let shell = RoundedRectangle(cornerRadius: style.panel.cornerRadius, style: .continuous)

        return shell
            .fill(
                colorScheme == .dark
                    ? Color.black.opacity(style.panel.shellBackgroundDarkOpacity)
                    : Color.white.opacity(style.panel.shellBackgroundLightOpacity)
            )
            .overlay {
                shell
                    .fill(.ultraThinMaterial)
                    .opacity(
                        colorScheme == .dark
                            ? style.panel.shellMaterialDarkOpacity
                            : style.panel.shellMaterialLightOpacity
                    )
            }
            .overlay {
                shell
                    .stroke(
                        Color.white.opacity(
                            colorScheme == .dark
                                ? style.panel.shellStrokeDarkOpacity
                                : style.panel.shellStrokeLightOpacity
                        ),
                        lineWidth: 0.7
                    )
            }
            .shadow(
                color: Color.black.opacity(
                    colorScheme == .dark
                        ? style.panel.shellShadowDarkOpacity
                        : style.panel.shellShadowLightOpacity
                ),
                radius: 8,
                x: 0,
                y: 2
            )
    }

    static func tabBackground(
        style: MathKeyboardStyle,
        isSelected: Bool,
        colorScheme: ColorScheme
    ) -> some View {
        let fillOpacity = isSelected
            ? style.tab.selectedBackgroundOpacity
            : style.tab.unselectedBackgroundOpacity

        let shape = RoundedRectangle(cornerRadius: style.tab.cornerRadius, style: .continuous)
        let baseColor: Color = isSelected ? .accentColor : .white

        return shape
            .fill(baseColor.opacity(fillOpacity))
            .overlay {
                shape.fill(.ultraThinMaterial).opacity(isSelected ? 0.16 : 0.10)
            }
            .overlay {
                shape.stroke(Color.white.opacity(colorScheme == .dark ? 0.16 : 0.20), lineWidth: 0.7)
            }
    }

    static func tabLabelColor(
        style: MathKeyboardStyle,
        isSelected: Bool,
        colorScheme: ColorScheme
    ) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(
                isSelected ? style.tab.selectedLabelDarkOpacity : style.tab.unselectedLabelDarkOpacity
            )
        }

        return Color.black.opacity(
            isSelected ? style.tab.selectedLabelLightOpacity : style.tab.unselectedLabelLightOpacity
        )
    }

    static func formulaDisplayStyle(
        baseColor: Color,
        role: MathInputKeyboardKeyVisualRole,
        style: MathKeyboardStyle
    ) -> FormulaDisplayStyle {
        let keycapMetrics = formulaLayoutMetrics(style: style, role: role)
        return FormulaDisplayStyle(
            textColor: baseColor,
            operatorColor: baseColor,
            functionColor: baseColor,
            rawTextColor: baseColor,
            errorTextColor: baseColor.opacity(role == .accent ? 0.92 : 0.74),
            cursorColor: baseColor,
            placeholderStrokeColor: baseColor.opacity(0.80),
            placeholderFillColor: .clear,
            fractionLineColor: baseColor,
            radicalColor: baseColor,
            delimiterColor: baseColor,
            debugColor: .clear,
            baseFont: .system(size: keycapMetrics.baseFontSize, weight: .semibold, design: .rounded),
            scriptScale: keycapMetrics.scriptScale
        )
    }

    static func formulaLayoutMetrics(
        style: MathKeyboardStyle,
        role: MathInputKeyboardKeyVisualRole
    ) -> FormulaLayoutMetrics {
        let isTemplate = role == .template
        let fontSize = isTemplate
            ? max(style.typography.templatePrimaryFontSize * 0.98, style.typography.primaryFontSize * 0.92)
            : style.typography.primaryFontSize * 0.94
        return FormulaLayoutMetrics(
            baseFontSize: fontSize,
            scriptScale: 0.64,
            minimumFontSize: max(8.5, fontSize * 0.56),
            operatorSpacing: 1.6,
            functionSpacing: isTemplate ? 0.96 : 1.2,
            fractionHorizontalPadding: isTemplate ? 1.7 : 2.1,
            fractionVerticalGap: isTemplate ? 1.55 : 1.9,
            fractionLineThickness: 0.78,
            sqrtHorizontalPadding: isTemplate ? 1.18 : 1.52,
            sqrtOverlineGap: 1.4,
            scriptVerticalRaise: max(5.2, fontSize * 0.54),
            subscriptVerticalDrop: max(3.8, fontSize * 0.35),
            delimiterHorizontalPadding: isTemplate ? 2.25 : 1.95,
            absoluteValueStrokeWidth: 0.62,
            rawFallbackPadding: 1.5,
            cursorWidth: 1.2,
            placeholderWidth: max(10.1, fontSize * 0.61),
            placeholderHeight: max(13.0, fontSize * 0.88),
            minimumBoxSize: .init(width: max(11.0, fontSize * 0.7), height: max(16.0, fontSize * 0.95))
        )
    }

    static func presentation(for key: MathKeyboardKey) -> MathInputKeyboardLabelPresentation {
        switch key.label {
        case .formula(let markup, _), .symbol(let markup, _):
            return .formulaMarkup(markup)
        case .text(let value):
            return .plainText(value)
        case .systemIcon(let systemName):
            return .systemImage(systemName)
        }
    }

    private static func isAccent(_ key: MathKeyboardKey) -> Bool {
        key.id.hasSuffix("submit") || key.id.hasSuffix("-submit") || key.id.hasSuffix("-eq")
    }
}
