import EMathicaMathInputCore
import Foundation
import EMathicaMathCore

public struct FormulaSemanticState: Equatable, Sendable {
    public var expression: Expr?
    public var diagnostics: [ExprDiagnostic]
    public var graphClassification: GraphClassificationResult?

    public static let empty = FormulaSemanticState(
        expression: nil,
        diagnostics: [],
        graphClassification: nil
    )

    public var hasBlockingError: Bool {
        diagnostics.contains { $0.severity == .error }
    }

    public func plotDiagnostics(source: FormulaPlotDiagnosticSource) -> [FormulaPlotDiagnostic] {
        var result = diagnostics.map { FormulaPlotDiagnostic.fromExpr($0, source: source) }
        if let graphClassification {
            result.append(contentsOf: graphClassification.diagnostics.map {
                FormulaPlotDiagnostic.fromGraph($0, source: source)
            })
        }
        return result
    }
}
