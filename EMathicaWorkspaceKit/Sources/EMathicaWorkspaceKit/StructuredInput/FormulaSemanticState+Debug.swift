import EMathicaMathInputCore
import Foundation
import EMathicaMathCore

public extension FormulaSemanticState {
    public var debugSummary: String {
        let exprText = expression.map { ExprDebugPrinter().print($0) } ?? "nil"
        let graphText = graphClassification.map {
            GraphIntentDebugPrinter().print($0.intent)
        } ?? "nil"
        let diagnosticsText: String
        if diagnostics.isEmpty {
            diagnosticsText = "[]"
        } else {
            diagnosticsText = diagnostics.map { diagnostic in
                "[\(diagnostic.severity.rawValue)] \(diagnostic.code.rawValue): \(diagnostic.message)"
            }.joined(separator: " | ")
        }
        return "expression=\(exprText); diagnostics=\(diagnosticsText); graph=\(graphText)"
    }
}
