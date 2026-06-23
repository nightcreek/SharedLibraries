import EMathicaMathInputCore
import Foundation
import EMathicaMathCore

public struct FormulaDiagnosticPresentation: Equatable {
    public var severity: FormulaPlotDiagnosticSeverity
    public var message: String
    public var code: String
}

public enum FormulaDiagnosticPresenter {
    public static func topPresentation(
        from diagnostics: [FormulaPlotDiagnostic],
        includeInfo: Bool = false
    ) -> FormulaDiagnosticPresentation? {
        let filtered = includeInfo
            ? diagnostics
            : diagnostics.filter { $0.severity != .info }

        guard let best = filtered.enumerated().max(by: { lhs, rhs in
            let l = priority(lhs.element.severity)
            let r = priority(rhs.element.severity)
            if l == r {
                return lhs.offset > rhs.offset
            }
            return l < r
        })?.element else {
            return nil
        }

        let trimmed = best.message.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = trimmed.isEmpty ? fallbackMessage(for: best) : trimmed
        return FormulaDiagnosticPresentation(
            severity: best.severity,
            message: message,
            code: best.code
        )
    }

    public static func topPresentation(
        from diagnostics: [AlgebraDiagnostic],
        includeInfo: Bool = false
    ) -> FormulaDiagnosticPresentation? {
        let converted = diagnostics.map { diagnostic in
            FormulaPlotDiagnostic(
                stage: .sampling,
                severity: severity(from: diagnostic.severity),
                code: "algebra_diagnostic",
                message: diagnostic.message,
                source: .committed
            )
        }
        return topPresentation(from: converted, includeInfo: includeInfo)
    }

    private static func priority(_ severity: FormulaPlotDiagnosticSeverity) -> Int {
        switch severity {
        case .error:
            return 3
        case .warning:
            return 2
        case .info:
            return 1
        }
    }

    private static func severity(from severity: AlgebraDiagnostic.Severity) -> FormulaPlotDiagnosticSeverity {
        switch severity {
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        }
    }

    private static func fallbackMessage(for diagnostic: FormulaPlotDiagnostic) -> String {
        switch diagnostic.severity {
        case .error:
            return "表达式无法绘制（\(diagnostic.code)）"
        case .warning:
            return "表达式可能不完整（\(diagnostic.code)）"
        case .info:
            return "已记录绘图信息（\(diagnostic.code)）"
        }
    }
}
