import Foundation
import EMathicaFormulaDisplayVendor

package struct FormulaRGBAColor: Sendable, Equatable {
    package var red: Double
    package var green: Double
    package var blue: Double
    package var alpha: Double

    package init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

package struct FormulaSwiftMathSnapshot: Sendable, Equatable {
    package var pngData: Data
    package var size: FormulaSize
    package var baseline: Double

    package init(pngData: Data, size: FormulaSize, baseline: Double) {
        self.pngData = pngData
        self.size = size
        self.baseline = baseline
    }
}

public struct FormulaSwiftMathRenderError: Error, Sendable, Equatable {
    public var domain: String
    public var code: Int
    public var message: String

    public init(domain: String, code: Int, message: String) {
        self.domain = domain
        self.code = code
        self.message = message
    }
}

package enum FormulaDisplayResolvedContent: Sendable, Equatable {
    case legacy(FormulaRenderPlan)
    case swiftMath(FormulaSwiftMathSnapshot)
    case swiftMathError(FormulaSwiftMathRenderError)
}

package enum FormulaDisplayContentResolver {
    package static func resolve(
        markup: FormulaDisplayMarkup,
        options: FormulaDisplayOptions,
        metrics: FormulaLayoutMetrics,
        foregroundColor: FormulaRGBAColor
    ) -> FormulaDisplayResolvedContent {
        switch options.renderingBackend {
        case .legacy:
            let plan = FormulaDisplayEngine(options: options, metrics: metrics).getPlan(from: markup)
            return .legacy(plan)
        case .swiftMath:
            return resolveSwiftMath(
                markup: markup,
                fontRole: options.fontRole,
                metrics: metrics,
                foregroundColor: foregroundColor
            )
        }
    }

    private static func resolveSwiftMath(
        markup: FormulaDisplayMarkup,
        fontRole: FormulaFontRole,
        metrics: FormulaLayoutMetrics,
        foregroundColor: FormulaRGBAColor
    ) -> FormulaDisplayResolvedContent {
        let trimmed = markup.rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .swiftMathError(
                .init(
                    domain: "EMathicaFormulaDisplayCore.SwiftMath",
                    code: 1000,
                    message: "SwiftMath read-only rendering requires non-empty markup."
                )
            )
        }

        let role = mapFontRole(fontRole)
        let color = SwiftMathVendorColor(
            red: foregroundColor.red,
            green: foregroundColor.green,
            blue: foregroundColor.blue,
            alpha: foregroundColor.alpha
        )

        switch SwiftMathReadOnlyRenderer.renderPNG(
            latex: trimmed,
            fontRole: role,
            fontSize: metrics.baseFontSize,
            foregroundColor: color,
            displayStyle: .display
        ) {
        case .success(let image):
            return .swiftMath(
                .init(
                    pngData: image.pngData,
                    size: .init(width: image.size.width, height: image.size.height),
                    baseline: image.baseline
                )
            )
        case .failure(let error):
            return .swiftMathError(
                .init(domain: error.domain, code: error.code, message: error.message)
            )
        }
    }

    private static func mapFontRole(_ role: FormulaFontRole) -> SwiftMathFontRole {
        switch role {
        case .standard:
            return .standard
        case .handwrittenResult:
            return .handwrittenResult
        case .decorative:
            return .decorative
        }
    }
}
