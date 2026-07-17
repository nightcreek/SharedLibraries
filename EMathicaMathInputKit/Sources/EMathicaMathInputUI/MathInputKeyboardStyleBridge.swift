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
}

enum MathInputKeyboardStyleBridge {
    static func keyVisualRole(for key: MathKeyboardKey) -> MathInputKeyboardKeyVisualRole {
        if isAccent(key) {
            return .accent
        }

        switch key.label {
        case .system:
            return .system
        case .formulaMarkup:
            return .template
        case .text:
            switch key.intent {
            case .input(.template), .action(.insertTemplate):
                return .template
            default:
                return .standard
            }
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

    static func presentation(for label: MathKeyboardKeyLabel) -> MathInputKeyboardLabelPresentation {
        switch label {
        case .formulaMarkup(let markup):
            return .formulaMarkup(markup)
        case .system(let symbol):
            return systemPresentation(for: symbol)
        case .text(let value):
            return mathPresentation(for: value)
        }
    }

    private static func systemPresentation(for symbol: String) -> MathInputKeyboardLabelPresentation {
        switch symbol {
        case "⌫":
            return .systemImage("delete.left")
        case "↵":
            return .systemImage("return.left")
        case "←":
            return .systemImage("arrow.left")
        case "→":
            return .systemImage("arrow.right")
        case "↑":
            return .systemImage("arrow.up")
        case "↓":
            return .systemImage("arrow.down")
        default:
            return .plainText(symbol)
        }
    }

    private static func mathPresentation(for value: String) -> MathInputKeyboardLabelPresentation {
        switch value {
        case "sin":
            return .formulaMarkup(#"\sin{\placeholder{}}"#)
        case "cos":
            return .formulaMarkup(#"\cos{\placeholder{}}"#)
        case "tan":
            return .formulaMarkup(#"\tan{\placeholder{}}"#)
        case "ln":
            return .formulaMarkup(#"\ln{\placeholder{}}"#)
        case "log":
            return .formulaMarkup(#"\log{\placeholder{}}"#)
        case "exp":
            return .formulaMarkup(#"exp(\placeholder{})"#)
        case "α":
            return .formulaMarkup(#"\alpha"#)
        case "Α":
            return .formulaMarkup(#"\Alpha"#)
        case "β":
            return .formulaMarkup(#"\beta"#)
        case "Β":
            return .formulaMarkup(#"\Beta"#)
        case "γ":
            return .formulaMarkup(#"\gamma"#)
        case "Γ":
            return .formulaMarkup(#"\Gamma"#)
        case "δ":
            return .formulaMarkup(#"\delta"#)
        case "Δ":
            return .formulaMarkup(#"\Delta"#)
        case "ε":
            return .formulaMarkup(#"\epsilon"#)
        case "Ε":
            return .formulaMarkup(#"\Epsilon"#)
        case "ζ":
            return .formulaMarkup(#"\zeta"#)
        case "Ζ":
            return .formulaMarkup(#"\Zeta"#)
        case "η":
            return .formulaMarkup(#"\eta"#)
        case "Η":
            return .formulaMarkup(#"\Eta"#)
        case "θ":
            return .formulaMarkup(#"\theta"#)
        case "Θ":
            return .formulaMarkup(#"\Theta"#)
        case "ι":
            return .formulaMarkup(#"\iota"#)
        case "Ι":
            return .formulaMarkup(#"\Iota"#)
        case "κ":
            return .formulaMarkup(#"\kappa"#)
        case "Κ":
            return .formulaMarkup(#"\Kappa"#)
        case "λ":
            return .formulaMarkup(#"\lambda"#)
        case "Λ":
            return .formulaMarkup(#"\Lambda"#)
        case "μ":
            return .formulaMarkup(#"\mu"#)
        case "Μ":
            return .formulaMarkup(#"\Mu"#)
        case "ν":
            return .formulaMarkup(#"\nu"#)
        case "Ν":
            return .formulaMarkup(#"\Nu"#)
        case "ξ":
            return .formulaMarkup(#"\xi"#)
        case "Ξ":
            return .formulaMarkup(#"\Xi"#)
        case "ο":
            return .formulaMarkup(#"\omicron"#)
        case "Ο":
            return .formulaMarkup(#"\Omicron"#)
        case "π":
            return .formulaMarkup(#"\pi"#)
        case "Π":
            return .formulaMarkup(#"\Pi"#)
        case "ρ":
            return .formulaMarkup(#"\rho"#)
        case "Ρ":
            return .formulaMarkup(#"\Rho"#)
        case "σ":
            return .formulaMarkup(#"\sigma"#)
        case "Σ":
            return .formulaMarkup(#"\Sigma"#)
        case "τ":
            return .formulaMarkup(#"\tau"#)
        case "Τ":
            return .formulaMarkup(#"\Tau"#)
        case "υ":
            return .formulaMarkup(#"\upsilon"#)
        case "Υ":
            return .formulaMarkup(#"\Upsilon"#)
        case "φ":
            return .formulaMarkup(#"\phi"#)
        case "Φ":
            return .formulaMarkup(#"\Phi"#)
        case "χ":
            return .formulaMarkup(#"\chi"#)
        case "Χ":
            return .formulaMarkup(#"\Chi"#)
        case "ψ":
            return .formulaMarkup(#"\psi"#)
        case "Ψ":
            return .formulaMarkup(#"\Psi"#)
        case "ω":
            return .formulaMarkup(#"\omega"#)
        case "Ω":
            return .formulaMarkup(#"\Omega"#)
        case "∞":
            return .formulaMarkup(#"\infty"#)
        case "∈":
            return .formulaMarkup(#"\in"#)
        case "∉":
            return .formulaMarkup(#"\notin"#)
        case "∅":
            return .formulaMarkup(#"\emptyset"#)
        case "×":
            return .formulaMarkup(#"\times"#)
        case "÷":
            return .formulaMarkup(#"\div"#)
        case "≤":
            return .formulaMarkup(#"\leq"#)
        case "≥":
            return .formulaMarkup(#"\geq"#)
        case "≠":
            return .formulaMarkup(#"\neq"#)
        default:
            if value.range(of: #"^[A-Za-z0-9+\-=/<>\[\]\(\)\{\}\.,|]+$"#, options: .regularExpression) != nil {
                return .formulaMarkup(value)
            }
            return .plainText(value)
        }
    }

    private static func isAccent(_ key: MathKeyboardKey) -> Bool {
        key.id.hasSuffix("submit") || key.id.hasSuffix("-submit") || key.id.hasSuffix("-eq")
    }
}
