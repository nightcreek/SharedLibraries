import EMathicaDocumentKit
import EMathicaMathCore
import Foundation

struct InspectorFormulaSourceLine: Equatable {
    var label: String
    var source: WorkspaceReadOnlyFormulaSource
}

enum InspectorFormulaSourceBuilder {
    static func objectLines(for object: MathObject) -> [InspectorFormulaSourceLine] {
        [
            .init(
                label: "显示",
                source: primaryDisplaySource(for: object)
            )
        ]
    }

    static func algebraLines(for analysis: AlgebraAnalysisResult) -> [InspectorFormulaSourceLine] {
        var lines: [InspectorFormulaSourceLine] = []
        appendFormulaLine(label: "rawInput", value: analysis.rawInput ?? analysis.originalLatex, to: &lines)
        appendFormulaLine(label: "normalizedExpression", value: analysis.normalizedExpression ?? analysis.normalizedLatex, to: &lines)
        appendFormulaLine(label: "simplifiedExpression", value: analysis.simplifiedExpression ?? analysis.simplifiedLatex, to: &lines)
        return lines
    }

    static func rewriteLines(for analysis: AlgebraAnalysisResult) -> [InspectorFormulaSourceLine] {
        guard let rewriteInfo = analysis.rewriteInfo else {
            return []
        }

        return [
            .init(label: "x(t)", source: inspectorSource(from: xEquation(rewriteInfo.curve))),
            .init(label: "y(t)", source: inspectorSource(from: yEquation(rewriteInfo.curve))),
            .init(label: "参数范围", source: inspectorSource(from: parameterRange(rewriteInfo.curve)))
        ]
    }

    static func inspectorSources(for object: MathObject) -> [WorkspaceReadOnlyFormulaSource] {
        var sources = objectLines(for: object).map(\.source)
        if let analysis = object.expression.algebraAnalysis {
            sources.append(contentsOf: algebraLines(for: analysis).map(\.source))
            sources.append(contentsOf: rewriteLines(for: analysis).map(\.source))
        }
        return sources
    }

    private static func primaryDisplaySource(for object: MathObject) -> WorkspaceReadOnlyFormulaSource {
        let objectSource = WorkspaceObjectFormulaSource.make(for: object)
        return .init(
            surface: .inspector,
            document: objectSource.document,
            rawValue: objectSource.rawValue,
            fallbackText: objectSource.fallbackText,
            fontSize: 13,
            minHeight: 20,
            allowsMultiline: true
        )
    }

    private static func inspectorSource(from value: String) -> WorkspaceReadOnlyFormulaSource {
        WorkspaceReadOnlyFormulaSource.make(
            surface: .inspector,
            rawValue: value,
            fallbackText: value,
            fontSize: 13,
            minHeight: 20,
            allowsMultiline: true
        )
    }

    private static func appendFormulaLine(
        label: String,
        value: String?,
        to lines: inout [InspectorFormulaSourceLine]
    ) {
        guard let value else { return }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lines.append(.init(label: label, source: inspectorSource(from: value)))
    }

    private static func xEquation(_ curve: ParametricCurveDefinition) -> String {
        switch curve.kind {
        case .circle, .ellipse:
            return "\(format(curve.centerX)) + \(format(curve.radiusX)) cos(t)"
        case .hyperbolaHorizontal:
            return "\(format(curve.centerX)) ± \(format(curve.radiusX)) cosh(t)"
        case .hyperbolaVertical:
            return "\(format(curve.centerX)) + \(format(curve.radiusX)) sinh(t)"
        case .parabolaHorizontal:
            return "\(format(curve.centerX)) + \(format(curve.focalParameter ?? 0)) t²"
        case .parabolaVertical:
            return "\(format(curve.centerX)) + \(format(2 * (curve.focalParameter ?? 0))) t"
        case .superellipse:
            break
        }
        let radius = curve.radiusXSymbol ?? format(curve.radiusX)
        let exponent = curve.exponentSymbol ?? format(curve.exponent)
        return "\(format(curve.centerX)) + \(radius) sign(cos(t)) |cos(t)|^(2/\(exponent))"
    }

    private static func yEquation(_ curve: ParametricCurveDefinition) -> String {
        switch curve.kind {
        case .circle, .ellipse:
            return "\(format(curve.centerY)) + \(format(curve.radiusY)) sin(t)"
        case .hyperbolaHorizontal:
            return "\(format(curve.centerY)) + \(format(curve.radiusY)) sinh(t)"
        case .hyperbolaVertical:
            return "\(format(curve.centerY)) ± \(format(curve.radiusY)) cosh(t)"
        case .parabolaHorizontal:
            return "\(format(curve.centerY)) + \(format(2 * (curve.focalParameter ?? 0))) t"
        case .parabolaVertical:
            return "\(format(curve.centerY)) + \(format(curve.focalParameter ?? 0)) t²"
        case .superellipse:
            break
        }
        let radius = curve.radiusYSymbol ?? format(curve.radiusY)
        let exponent = curve.exponentSymbol ?? format(curve.exponent)
        return "\(format(curve.centerY)) + \(radius) sign(sin(t)) |sin(t)|^(2/\(exponent))"
    }

    private static func parameterRange(_ curve: ParametricCurveDefinition) -> String {
        switch curve.kind {
        case .circle, .ellipse, .superellipse:
            return "t ∈ [0, 2π]"
        case .hyperbolaHorizontal, .hyperbolaVertical, .parabolaHorizontal, .parabolaVertical:
            return "t ∈ ℝ"
        }
    }

    private static func format(_ value: Double) -> String {
        let rounded = (value * 1000).rounded() / 1000
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}
