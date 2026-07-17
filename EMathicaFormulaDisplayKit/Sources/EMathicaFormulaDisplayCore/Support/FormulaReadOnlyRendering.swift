import Foundation
import EMathicaFormulaDisplayVendor

public enum FormulaDisplayContentInspector {
    public static func isEffectivelyEmpty(_ document: FormulaDisplayDocument) -> Bool {
        isEffectivelyEmpty(document.root)
    }

    public static func isEffectivelyEmpty(_ markup: FormulaDisplayMarkup) -> Bool {
        let sanitized = markup.rawValue
            .replacingOccurrences(of: #"\cursor{}"#, with: "")
            .replacingOccurrences(of: #"\cursor"#, with: "")
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func isEffectivelyEmpty(_ node: FormulaDisplayNode) -> Bool {
        switch node {
        case .sequence(let children):
            return children.allSatisfy(isEffectivelyEmpty)
        case .text(let value, _):
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .raw(let value):
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .error(let node):
            return node.rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .cursor:
            return true
        case .operatorSymbol,
             .function,
             .fraction,
             .sqrt,
             .nthRoot,
             .superscript,
             .subscript,
             .scriptPair,
             .parentheses,
             .brackets,
             .braces,
             .absoluteValue,
             .accent,
             .matrix,
             .cases,
             .limit,
             .largeOperator,
             .integral,
             .parametric2D,
             .parametric3D,
             .piecewise,
             .placeholder:
            return false
        }
    }
}

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
    package var cursorAnchor: FormulaCursorAnchor?
    package var placeholderAnchors: [FormulaPlaceholderAnchor]

    package init(
        pngData: Data,
        size: FormulaSize,
        baseline: Double,
        cursorAnchor: FormulaCursorAnchor? = nil,
        placeholderAnchors: [FormulaPlaceholderAnchor] = []
    ) {
        self.pngData = pngData
        self.size = size
        self.baseline = baseline
        self.cursorAnchor = cursorAnchor
        self.placeholderAnchors = placeholderAnchors
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
        document: FormulaDisplayDocument,
        options: FormulaDisplayOptions,
        metrics: FormulaLayoutMetrics,
        foregroundColor: FormulaRGBAColor
    ) -> FormulaDisplayResolvedContent {
        if FormulaDisplayContentInspector.isEffectivelyEmpty(document) {
            return .swiftMathError(
                .init(
                    domain: "EMathicaFormulaDisplayCore.SwiftMath",
                    code: 1000,
                    message: "Formula document is empty."
                )
            )
        }

        switch options.renderingBackend {
        case .legacy:
            let plan = FormulaDisplayEngine(options: options, metrics: metrics)
                .getPlan(from: .init(rawValue: FormulaDisplayDocumentSerializer.serialize(document)))
            return .legacy(plan)
        case .swiftMath:
            let lowered = FormulaDisplaySwiftMathLowerer.lower(document)
            return resolveSwiftMath(
                latex: lowered.latex,
                anchorLatex: lowered.anchorLatex,
                placeholderTokens: lowered.placeholderTokens,
                cursorToken: lowered.cursorToken,
                fontRole: options.fontRole,
                metrics: metrics,
                foregroundColor: foregroundColor
            )
        }
    }

    package static func resolve(
        markup: FormulaDisplayMarkup,
        options: FormulaDisplayOptions,
        metrics: FormulaLayoutMetrics,
        foregroundColor: FormulaRGBAColor
    ) -> FormulaDisplayResolvedContent {
        if FormulaDisplayContentInspector.isEffectivelyEmpty(markup) {
            return .swiftMathError(
                .init(
                    domain: "EMathicaFormulaDisplayCore.SwiftMath",
                    code: 1000,
                    message: "Formula markup is empty."
                )
            )
        }

        switch options.renderingBackend {
        case .legacy:
            let plan = FormulaDisplayEngine(options: options, metrics: metrics).getPlan(from: markup)
            return .legacy(plan)
        case .swiftMath:
            return resolveSwiftMath(
                latex: markup.rawValue,
                fontRole: options.fontRole,
                metrics: metrics,
                foregroundColor: foregroundColor
            )
        }
    }

    private static func resolveSwiftMath(
        latex: String,
        anchorLatex: String? = nil,
        placeholderTokens: [FormulaDisplayPlaceholderToken] = [],
        cursorToken: FormulaDisplayCursorToken? = nil,
        fontRole: FormulaFontRole,
        metrics: FormulaLayoutMetrics,
        foregroundColor: FormulaRGBAColor
    ) -> FormulaDisplayResolvedContent {
        let trimmed = latex.trimmingCharacters(in: .whitespacesAndNewlines)
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
            let placeholderAnchors = resolvePlaceholderAnchors(
                visibleImage: image,
                anchorLatex: anchorLatex ?? trimmed,
                placeholderTokens: placeholderTokens,
                role: role,
                fontSize: metrics.baseFontSize,
                color: color
            )
            return .swiftMath(
                .init(
                    pngData: image.pngData,
                    size: .init(width: image.size.width, height: image.size.height),
                    baseline: image.baseline,
                    cursorAnchor: image.cursorAnchor.map {
                        FormulaCursorAnchor(
                            id: cursorToken?.id,
                            rect: .init(
                                origin: .init(x: $0.rect.origin.x, y: $0.rect.origin.y),
                                size: .init(width: $0.rect.size.width, height: $0.rect.size.height)
                            ),
                            x: $0.x,
                            baseline: $0.baseline,
                            ascent: $0.ascent,
                            descent: $0.descent,
                            context: mapCursorContext($0.context),
                            sourcePath: cursorToken?.sourcePath ?? [],
                            fieldIdentity: cursorToken?.fieldIdentity
                        )
                    },
                    placeholderAnchors: placeholderAnchors
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

    private static func mapCursorContext(_ context: SwiftMathCursorContext) -> FormulaCursorContext {
        switch context {
        case .inline:
            return .inline
        case .numerator:
            return .numerator
        case .denominator:
            return .denominator
        case .radicalDegree:
            return .radicalDegree
        case .radicalRadicand:
            return .radicalRadicand
        case .superscript:
            return .superscript
        case .subscriptField:
            return .subscriptField
        case .unknown:
            return .unknown
        }
    }

    private static func resolvePlaceholderAnchors(
        visibleImage: SwiftMathRenderedImage,
        anchorLatex: String,
        placeholderTokens: [FormulaDisplayPlaceholderToken],
        role: SwiftMathFontRole,
        fontSize: Double,
        color: SwiftMathVendorColor
    ) -> [FormulaPlaceholderAnchor] {
        guard !placeholderTokens.isEmpty else {
            return []
        }

        let anchorSource = anchorLatex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !anchorSource.isEmpty else {
            return []
        }

        let renderedAnchorImage: SwiftMathRenderedImage
        switch SwiftMathReadOnlyRenderer.renderPNG(
            latex: anchorSource,
            fontRole: role,
            fontSize: fontSize,
            foregroundColor: color,
            displayStyle: .display
        ) {
        case .success(let anchorImage):
            renderedAnchorImage = anchorImage
        case .failure:
            return zip(placeholderTokens, visibleImage.placeholderAnchors).map { token, anchor in
                makePlaceholderAnchor(token: token, anchor: anchor)
            }
        }

        let candidateAnchors = renderedAnchorImage.placeholderAnchors.isEmpty ? visibleImage.placeholderAnchors : renderedAnchorImage.placeholderAnchors
        return zip(placeholderTokens, candidateAnchors).map { token, anchor in
            makePlaceholderAnchor(token: token, anchor: anchor)
        }
    }

    private static func makePlaceholderAnchor(
        token: FormulaDisplayPlaceholderToken,
        anchor: SwiftMathPlaceholderAnchor
    ) -> FormulaPlaceholderAnchor {
        FormulaPlaceholderAnchor(
            id: token.id,
            rect: .init(
                origin: .init(x: anchor.rect.origin.x, y: anchor.rect.origin.y),
                size: .init(width: anchor.rect.size.width, height: anchor.rect.size.height)
            ),
            baseline: anchor.baseline,
            ascent: anchor.ascent,
            descent: anchor.descent,
            context: mapCursorContext(anchor.context),
            sourcePath: token.sourcePath,
            fieldIdentity: token.fieldIdentity,
            kind: token.kind,
            widthPolicy: token.widthPolicy
        )
    }
}

package struct FormulaDisplaySwiftMathLoweringResult: Sendable, Equatable {
    package var latex: String
    package var anchorLatex: String
    package var placeholderTokens: [FormulaDisplayPlaceholderToken]
    package var cursorToken: FormulaDisplayCursorToken?
}

package enum FormulaDisplaySwiftMathLowerer {
    package static func lower(_ document: FormulaDisplayDocument) -> FormulaDisplaySwiftMathLoweringResult {
        var placeholderTokens: [FormulaDisplayPlaceholderToken] = []
        var cursorToken: FormulaDisplayCursorToken?
        let lowered = lower(
            document.root,
            placeholderTokens: &placeholderTokens,
            cursorToken: &cursorToken,
            syntheticPlaceholderCounter: 0
        )
        return .init(
            latex: lowered.visibleLatex,
            anchorLatex: lowered.anchorLatex,
            placeholderTokens: placeholderTokens,
            cursorToken: cursorToken
        )
    }

    private static func lower(
        _ node: FormulaDisplayNode,
        placeholderTokens: inout [FormulaDisplayPlaceholderToken],
        cursorToken: inout FormulaDisplayCursorToken?,
        syntheticPlaceholderCounter: Int
    ) -> (visibleLatex: String, anchorLatex: String, nextSyntheticCounter: Int) {
        var counter = syntheticPlaceholderCounter
        switch node {
        case .sequence(let children):
            let parts = children.map { child -> (String, String) in
                let lowered = lower(
                    child,
                    placeholderTokens: &placeholderTokens,
                    cursorToken: &cursorToken,
                    syntheticPlaceholderCounter: counter
                )
                counter = lowered.nextSyntheticCounter
                return (lowered.visibleLatex, lowered.anchorLatex)
            }
            return (
                joinLatexSegments(parts.map(\.0)),
                joinLatexSegments(parts.map(\.1)),
                counter
            )
        case .text(let value, _):
            return (value, value, counter)
        case .operatorSymbol(let value):
            return (value, value, counter)
        case .function(let name, let arguments):
            return lowerFunction(
                name: name,
                arguments: arguments,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
        case .fraction(let numerator, let denominator):
            let numeratorLowered = lower(
                numerator,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = numeratorLowered.nextSyntheticCounter
            let denominatorLowered = lower(
                denominator,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = denominatorLowered.nextSyntheticCounter
            return (
                #"\frac{\#(numeratorLowered.visibleLatex)}{\#(denominatorLowered.visibleLatex)}"#,
                #"\frac{\#(numeratorLowered.anchorLatex)}{\#(denominatorLowered.anchorLatex)}"#,
                counter
            )
        case .sqrt(let radicand):
            let lowered = lower(
                radicand,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\sqrt{\#(lowered.visibleLatex)}"#,
                #"\sqrt{\#(lowered.anchorLatex)}"#,
                lowered.nextSyntheticCounter
            )
        case .nthRoot(let index, let radicand):
            let indexLowered = lower(
                index,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = indexLowered.nextSyntheticCounter
            let radicandLowered = lower(
                radicand,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\sqrt[\#(indexLowered.visibleLatex)]{\#(radicandLowered.visibleLatex)}"#,
                #"\sqrt[\#(indexLowered.anchorLatex)]{\#(radicandLowered.anchorLatex)}"#,
                radicandLowered.nextSyntheticCounter
            )
        case .superscript(let base, let exponent):
            let baseLowered = lower(
                base,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = baseLowered.nextSyntheticCounter
            let exponentLowered = lower(
                exponent,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                "\(baseLowered.visibleLatex)^{\(exponentLowered.visibleLatex)}",
                "\(baseLowered.anchorLatex)^{\(exponentLowered.anchorLatex)}",
                exponentLowered.nextSyntheticCounter
            )
        case .subscript(let base, let subscriptNode):
            let baseLowered = lower(
                base,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = baseLowered.nextSyntheticCounter
            let subscriptLowered = lower(
                subscriptNode,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                "\(baseLowered.visibleLatex)_{\((subscriptLowered.visibleLatex))}",
                "\(baseLowered.anchorLatex)_{\((subscriptLowered.anchorLatex))}",
                subscriptLowered.nextSyntheticCounter
            )
        case .scriptPair(let base, let subscriptNode, let superscriptNode):
            let baseLowered = lower(
                base,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = baseLowered.nextSyntheticCounter
            var visibleOutput = baseLowered.visibleLatex
            var anchorOutput = baseLowered.anchorLatex
            if let superscriptNode {
                let superscriptLowered = lower(
                    superscriptNode,
                    placeholderTokens: &placeholderTokens,
                    cursorToken: &cursorToken,
                    syntheticPlaceholderCounter: counter
                )
                counter = superscriptLowered.nextSyntheticCounter
                visibleOutput += "^{\(superscriptLowered.visibleLatex)}"
                anchorOutput += "^{\(superscriptLowered.anchorLatex)}"
            }
            if let subscriptNode {
                let subscriptLowered = lower(
                    subscriptNode,
                    placeholderTokens: &placeholderTokens,
                    cursorToken: &cursorToken,
                    syntheticPlaceholderCounter: counter
                )
                counter = subscriptLowered.nextSyntheticCounter
                visibleOutput += "_{\(subscriptLowered.visibleLatex)}"
                anchorOutput += "_{\(subscriptLowered.anchorLatex)}"
            }
            return (visibleOutput, anchorOutput, counter)
        case .parentheses(let content):
            let lowered = lower(
                content,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return ("(\(lowered.visibleLatex))", "(\(lowered.anchorLatex))", lowered.nextSyntheticCounter)
        case .brackets(let content):
            let lowered = lower(
                content,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return ("[\(lowered.visibleLatex)]", "[\(lowered.anchorLatex)]", lowered.nextSyntheticCounter)
        case .braces(let content):
            let lowered = lower(
                content,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\{\#(lowered.visibleLatex)\}"#,
                #"\{\#(lowered.anchorLatex)\}"#,
                lowered.nextSyntheticCounter
            )
        case .absoluteValue(let content):
            let lowered = lower(
                content,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return ("|\(lowered.visibleLatex)|", "|\(lowered.anchorLatex)|", lowered.nextSyntheticCounter)
        case .accent(let style, let content):
            let lowered = lower(
                content,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            let command: String
            switch style {
            case .vector:
                command = #"\vec"#
            case .overline:
                command = #"\overline"#
            case .hat:
                command = #"\hat"#
            }
            return (
                #"\#(command){\#(lowered.visibleLatex)}"#,
                #"\#(command){\#(lowered.anchorLatex)}"#,
                lowered.nextSyntheticCounter
            )
        case .matrix(let environment, let rows):
            let body = lowerGridRows(
                rows,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\begin{\#(matrixEnvironmentName(environment))}\#(body.visibleLatex)\end{\#(matrixEnvironmentName(environment))}"#,
                #"\begin{\#(matrixEnvironmentName(environment))}\#(body.anchorLatex)\end{\#(matrixEnvironmentName(environment))}"#,
                body.nextSyntheticCounter
            )
        case .cases(let rows):
            let body = lowerGridRows(
                rows,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\begin{cases}\#(body.visibleLatex)\end{cases}"#,
                #"\begin{cases}\#(body.anchorLatex)\end{cases}"#,
                body.nextSyntheticCounter
            )
        case .limit(let variable, let target, let body):
            let variableLowered = lower(
                variable,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = variableLowered.nextSyntheticCounter
            let targetLowered = lower(
                target,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = targetLowered.nextSyntheticCounter
            let bodyLowered = lower(
                body,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\lim_{\#(variableLowered.visibleLatex)\to\#(targetLowered.visibleLatex)} \#(bodyLowered.visibleLatex)"#,
                #"\lim_{\#(variableLowered.anchorLatex)\to\#(targetLowered.anchorLatex)} \#(bodyLowered.anchorLatex)"#,
                bodyLowered.nextSyntheticCounter
            )
        case .largeOperator(let kind, let variable, let lowerBound, let upperBound, let body):
            let variableLowered = lower(
                variable,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = variableLowered.nextSyntheticCounter
            let lowerBoundLowered = lower(
                lowerBound,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = lowerBoundLowered.nextSyntheticCounter
            let upperBoundLowered = lower(
                upperBound,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = upperBoundLowered.nextSyntheticCounter
            let bodyLowered = lower(
                body,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            let command = kind == .sum ? #"\sum"# : #"\prod"#
            return (
                #"\#(command)_{\#(variableLowered.visibleLatex)=\#(lowerBoundLowered.visibleLatex)}^{\#(upperBoundLowered.visibleLatex)} \#(bodyLowered.visibleLatex)"#,
                #"\#(command)_{\#(variableLowered.anchorLatex)=\#(lowerBoundLowered.anchorLatex)}^{\#(upperBoundLowered.anchorLatex)} \#(bodyLowered.anchorLatex)"#,
                bodyLowered.nextSyntheticCounter
            )
        case .integral(let lowerBound, let upperBound, let integrand, let variable):
            let lowerBoundLowered = lower(
                lowerBound,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = lowerBoundLowered.nextSyntheticCounter
            let upperBoundLowered = lower(
                upperBound,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = upperBoundLowered.nextSyntheticCounter
            let integrandLowered = lower(
                integrand,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = integrandLowered.nextSyntheticCounter
            let variableLowered = lower(
                variable,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\int_{\#(lowerBoundLowered.visibleLatex)}^{\#(upperBoundLowered.visibleLatex)} \#(integrandLowered.visibleLatex)\,d\#(variableLowered.visibleLatex)"#,
                #"\int_{\#(lowerBoundLowered.anchorLatex)}^{\#(upperBoundLowered.anchorLatex)} \#(integrandLowered.anchorLatex)\,d\#(variableLowered.anchorLatex)"#,
                variableLowered.nextSyntheticCounter
            )
        case .parametric2D(let x, let y, let range):
            let xLowered = lower(
                x,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = xLowered.nextSyntheticCounter
            let yLowered = lower(
                y,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = yLowered.nextSyntheticCounter
            let rangeMarkup: (visible: String, anchor: String)
            if let range {
                let rangeLowered = lower(
                    range,
                    placeholderTokens: &placeholderTokens,
                    cursorToken: &cursorToken,
                    syntheticPlaceholderCounter: counter
                )
                counter = rangeLowered.nextSyntheticCounter
                rangeMarkup = (rangeLowered.visibleLatex, rangeLowered.anchorLatex)
            } else {
                let synthetic = FormulaDisplayPlaceholderToken(
                    id: "placeholder:synthetic:\(counter)",
                    sourcePath: [],
                    fieldIdentity: "parametricRange",
                    kind: "parametricRange",
                    widthPolicy: .quad
                )
                placeholderTokens.append(synthetic)
                rangeMarkup = (#"\quad"#, #"\emplaceholder{}"#)
                counter += 1
            }
            let visibleBody = #"\begin{cases}x=\#(xLowered.visibleLatex)\\y=\#(yLowered.visibleLatex)\end{cases}"#
            let anchorBody = #"\begin{cases}x=\#(xLowered.anchorLatex)\\y=\#(yLowered.anchorLatex)\end{cases}"#
            return (
                visibleBody + #",\ t\in \#(rangeMarkup.visible)"#,
                anchorBody + #",\ t\in \#(rangeMarkup.anchor)"#,
                counter
            )
        case .parametric3D(let x, let y, let z):
            let xLowered = lower(
                x,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = xLowered.nextSyntheticCounter
            let yLowered = lower(
                y,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = yLowered.nextSyntheticCounter
            let zLowered = lower(
                z,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            return (
                #"\begin{cases}x=\#(xLowered.visibleLatex)\\y=\#(yLowered.visibleLatex)\\z=\#(zLowered.visibleLatex)\end{cases}"#,
                #"\begin{cases}x=\#(xLowered.anchorLatex)\\y=\#(yLowered.anchorLatex)\\z=\#(zLowered.anchorLatex)\end{cases}"#,
                zLowered.nextSyntheticCounter
            )
        case .piecewise(let rows):
            var visibleRowMarkup = ""
            var anchorRowMarkup = ""
            for rowIndex in rows.indices {
                let row = rows[rowIndex]
                let expressionLowered = lower(
                    row.expression,
                    placeholderTokens: &placeholderTokens,
                    cursorToken: &cursorToken,
                    syntheticPlaceholderCounter: counter
                )
                counter = expressionLowered.nextSyntheticCounter
                let conditionLowered = lower(
                    row.condition,
                    placeholderTokens: &placeholderTokens,
                    cursorToken: &cursorToken,
                    syntheticPlaceholderCounter: counter
                )
                counter = conditionLowered.nextSyntheticCounter
                visibleRowMarkup += "\(expressionLowered.visibleLatex),&\(conditionLowered.visibleLatex)"
                anchorRowMarkup += "\(expressionLowered.anchorLatex),&\(conditionLowered.anchorLatex)"
                if rowIndex < rows.count - 1 {
                    visibleRowMarkup += #"\\\\"#
                    anchorRowMarkup += #"\\\\"#
                }
            }
            return (
                #"\begin{cases}\#(visibleRowMarkup)\end{cases}"#,
                #"\begin{cases}\#(anchorRowMarkup)\end{cases}"#,
                counter
            )
        case .cursor(let token):
            cursorToken = token
            switch token.spacingPolicy {
            case .medium:
                return (#"\emcursor{}"#, #"\emcursor{}"#, counter)
            case .thick:
                return (#"\emcursorthick{}"#, #"\emcursorthick{}"#, counter)
            }
        case .placeholder(let token):
            placeholderTokens.append(token)
            return (#"\quad"#, #"\emplaceholder{}"#, counter)
        case .raw(let value):
            return (value, value, counter)
        case .error(let node):
            return (node.rawText, node.rawText, counter)
        }
    }

    private static func lowerFunction(
        name: String,
        arguments: [FormulaDisplayNode],
        placeholderTokens: inout [FormulaDisplayPlaceholderToken],
        cursorToken: inout FormulaDisplayCursorToken?,
        syntheticPlaceholderCounter: Int
    ) -> (visibleLatex: String, anchorLatex: String, nextSyntheticCounter: Int) {
        var counter = syntheticPlaceholderCounter
        guard let first = arguments.first else {
            return ("\\\(name)", "\\\(name)", counter)
        }

        let loweredArguments = [first] + Array(arguments.dropFirst())
        let lowered = loweredArguments.map { argument -> (String, String) in
            let lowered = lower(
                argument,
                placeholderTokens: &placeholderTokens,
                cursorToken: &cursorToken,
                syntheticPlaceholderCounter: counter
            )
            counter = lowered.nextSyntheticCounter
            return (lowered.visibleLatex, lowered.anchorLatex)
        }

        let parenthesizedFunctions: Set<String> = [
            "sin", "cos", "tan", "cot", "sec", "csc",
            "arcsin", "arccos", "arctan",
            "sinh", "cosh", "tanh",
            "ln", "lg", "log", "exp"
        ]

        if name == "log", lowered.count > 1 {
            return (
                "\\log_\(brace(lowered[0].0))(\(lowered[1].0))",
                "\\log_\(brace(lowered[0].1))(\(lowered[1].1))",
                counter
            )
        }

        if parenthesizedFunctions.contains(name) {
            return ("\\\(name)(\(lowered[0].0))", "\\\(name)(\(lowered[0].1))", counter)
        }

        let visibleTrailing = lowered.dropFirst().map { "{\($0.0)}" }.joined()
        let anchorTrailing = lowered.dropFirst().map { "{\($0.1)}" }.joined()
        return (
            "\\\(name)\(brace(lowered[0].0))\(visibleTrailing)",
            "\\\(name)\(brace(lowered[0].1))\(anchorTrailing)",
            counter
        )
    }

    private static func brace(_ latex: String) -> String {
        "{\(latex)}"
    }

    private static func joinLatexSegments(_ segments: [String]) -> String {
        guard var output = segments.first else {
            return ""
        }

        for segment in segments.dropFirst() {
            if needsLatexCommandBoundary(after: output, before: segment) {
                output += "{}"
            }
            output += segment
        }

        return output
    }

    private static func needsLatexCommandBoundary(after previous: String, before next: String) -> Bool {
        guard
            let nextScalar = next.unicodeScalars.first,
            CharacterSet.letters.contains(nextScalar)
        else {
            return false
        }

        guard let backslashIndex = previous.lastIndex(of: "\\") else {
            return false
        }

        let suffix = previous[backslashIndex...]
        guard suffix.count > 1 else {
            return false
        }

        return suffix.dropFirst().allSatisfy { character in
            character.unicodeScalars.allSatisfy { scalar in
                scalar.isASCII && CharacterSet.letters.contains(scalar)
            }
        }
    }

    private static func lowerGridRows(
        _ rows: [FormulaGridRow],
        placeholderTokens: inout [FormulaDisplayPlaceholderToken],
        cursorToken: inout FormulaDisplayCursorToken?,
        syntheticPlaceholderCounter: Int
    ) -> (visibleLatex: String, anchorLatex: String, nextSyntheticCounter: Int) {
        var counter = syntheticPlaceholderCounter
        let renderedRows = rows.enumerated().map { rowIndex, row -> (String, String) in
            let cells = row.cells.map { cell -> (String, String) in
                let lowered = lower(
                    cell,
                    placeholderTokens: &placeholderTokens,
                    cursorToken: &cursorToken,
                    syntheticPlaceholderCounter: counter
                )
                counter = lowered.nextSyntheticCounter
                return (lowered.visibleLatex, lowered.anchorLatex)
            }
            return (
                cells.map(\.0).joined(separator: "&"),
                cells.map(\.1).joined(separator: "&")
            )
        }
        return (
            renderedRows.map(\.0).joined(separator: #"\\\\"#),
            renderedRows.map(\.1).joined(separator: #"\\\\"#),
            counter
        )
    }

    private static func matrixEnvironmentName(_ environment: FormulaMatrixEnvironment) -> String {
        switch environment {
        case .matrix:
            return "matrix"
        case .pmatrix:
            return "pmatrix"
        case .bmatrix:
            return "bmatrix"
        case .vmatrix:
            return "vmatrix"
        case .Vmatrix:
            return "Vmatrix"
        case .smallmatrix:
            return "smallmatrix"
        }
    }
}
