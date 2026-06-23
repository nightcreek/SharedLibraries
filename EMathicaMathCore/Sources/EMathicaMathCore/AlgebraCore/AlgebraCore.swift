import Foundation

public enum AlgebraCore {
    public nonisolated static func analyzePlaneLatex(_ input: String) -> AlgebraAnalysisResult {
        let parser = AlgebraLatexParser(input)
        let parseResult = parser.parse()

        let simplifiedRelation: AlgebraRelation
        var diagnostics = parseResult.diagnostics
        switch parseResult.relation {
        case .expression(let expression):
            let outcome = AlgebraSimplifier.simplifyWithDiagnostics(expression)
            simplifiedRelation = .expression(outcome.expression)
            diagnostics.append(contentsOf: outcome.diagnostics)
        case .equation(let equation):
            let left = AlgebraSimplifier.simplifyWithDiagnostics(equation.left)
            let right = AlgebraSimplifier.simplifyWithDiagnostics(equation.right)
            simplifiedRelation = .equation(AlgebraEquation(
                left: left.expression,
                right: right.expression
            ))
            diagnostics.append(contentsOf: left.diagnostics + right.diagnostics)
        }

        let variableSet = AlgebraVariableAnalyzer.variables(in: simplifiedRelation, plottingSymbols: ["x", "y"])
        let parameterSet = AlgebraVariableAnalyzer.parameters(in: simplifiedRelation, plottingSymbols: ["x", "y"])
        let baseClassification = PlaneAlgebraClassifier.classify(simplifiedRelation)
        let shouldPreferExplicitClassification: Bool = {
            switch baseClassification.kind {
            case .explicitY, .explicitX, .horizontalLine, .verticalLine:
                return true
            default:
                return false
            }
        }()
        let rewriteInfo: ParametricRewriteInfo? = shouldPreferExplicitClassification
            ? nil
            : (SuperellipseRecognizer.recognize(simplifiedRelation)
                ?? ConicParametricRewriter.recognize(simplifiedRelation))
        let classification = rewriteInfo == nil
            ? baseClassification
            : PlaneAlgebraClassifier.classify(simplifiedRelation, rewriteInfo: rewriteInfo)
        let plotStrategy = plotStrategy(for: classification, rewriteInfo: rewriteInfo)
        let normalizedLatex = AlgebraLatexFormatter.format(parseResult.relation)
        let simplifiedLatex = AlgebraLatexFormatter.format(simplifiedRelation)
        let displayText = AlgebraDisplayFormatter.format(simplifiedRelation)

        return AlgebraAnalysisResult(
            rawInput: input,
            normalizedExpression: normalizedLatex,
            simplifiedExpression: simplifiedLatex,
            originalLatex: input,
            normalizedLatex: normalizedLatex,
            simplifiedLatex: simplifiedLatex,
            displayText: displayText,
            simplifiedDisplayText: displayText,
            variables: Array(variableSet).sorted(),
            parameters: Array(parameterSet).sorted(),
            classification: classification,
            recognizedShape: rewriteInfo?.shapeKind,
            plotStrategy: plotStrategy,
            rewriteInfo: rewriteInfo,
            restrictions: restrictions(for: rewriteInfo),
            unresolvedSymbols: Array(parameterSet).sorted(),
            diagnostics: diagnostics,
            relation: parseResult.relation,
            simplifiedRelation: simplifiedRelation
        )
    }

    private static func plotStrategy(
        for classification: AlgebraClassification,
        rewriteInfo: ParametricRewriteInfo?
    ) -> PlotStrategyKind {
        if rewriteInfo != nil {
            return .parametric
        }
        switch classification.kind {
        case .explicitY:
            return .explicitY
        case .explicitX:
            return .explicitX
        case .horizontalLine:
            return .horizontalLine
        case .verticalLine:
            return .verticalLine
        case .circle, .ellipse:
            return .conicParametric
        case .implicitPlaneCurve, .hyperbola, .parabola:
            return .implicit
        case .superellipse:
            return .parametric
        case .unsupported:
            return .unsupported
        }
    }

    private static func restrictions(for rewriteInfo: ParametricRewriteInfo?) -> [String] {
        guard let rewriteInfo else { return [] }
        switch rewriteInfo.shapeKind {
        case .circle, .ellipse:
            return ["t ∈ [0, 2π]"]
        case .hyperbola:
            return ["t ∈ ℝ", "按当前视口动态采样两支"]
        case .parabola:
            return ["t ∈ ℝ", "按当前视口动态采样"]
        case .superellipse:
            let curve = rewriteInfo.curve
            var restrictions = ["t ∈ [0, 2π]"]
            restrictions.append("\(curve.exponentSymbol ?? "n") > 0")
            restrictions.append("\(curve.radiusXSymbol ?? "A") ≠ 0")
            restrictions.append("\(curve.radiusYSymbol ?? "B") ≠ 0")
            return restrictions
        }
    }
}
