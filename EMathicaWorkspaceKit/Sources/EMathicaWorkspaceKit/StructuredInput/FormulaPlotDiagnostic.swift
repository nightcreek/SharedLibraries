import EMathicaMathInputCore
import Foundation
import EMathicaMathCore

public enum FormulaPlotDiagnosticStage: String, Codable, Hashable, Sendable {
    case serialization
    case parse
    case classification
    case fallback
    case sampling
    case rendering
}

public enum FormulaPlotDiagnosticSeverity: String, Codable, Hashable, Sendable {
    case info
    case warning
    case error
}

public enum FormulaPlotDiagnosticSource: String, Codable, Hashable, Sendable {
    case draft
    case committed
}

public struct FormulaPlotDiagnostic: Hashable, Codable, Sendable {
    public init(stage: FormulaPlotDiagnosticStage, severity: FormulaPlotDiagnosticSeverity, code: String, message: String, source: FormulaPlotDiagnosticSource) { self.stage = stage; self.severity = severity; self.code = code; self.message = message; self.source = source }
    public var stage: FormulaPlotDiagnosticStage
    public var severity: FormulaPlotDiagnosticSeverity
    public var code: String
    public var message: String
    public var source: FormulaPlotDiagnosticSource
}

public extension FormulaPlotDiagnostic {
    public static func fromExpr(
        _ diagnostic: ExprDiagnostic,
        source: FormulaPlotDiagnosticSource
    ) -> FormulaPlotDiagnostic {
        FormulaPlotDiagnostic(
            stage: .serialization,
            severity: fromExprSeverity(diagnostic.severity),
            code: diagnostic.code.rawValue,
            message: diagnostic.message,
            source: source
        )
    }

    public static func fromGraph(
        _ diagnostic: GraphDiagnostic,
        source: FormulaPlotDiagnosticSource
    ) -> FormulaPlotDiagnostic {
        FormulaPlotDiagnostic(
            stage: .classification,
            severity: fromGraphSeverity(diagnostic.severity),
            code: diagnostic.code.rawValue,
            message: diagnostic.message,
            source: source
        )
    }

    public static func fromSampling(
        _ issue: SamplingIssue,
        source: FormulaPlotDiagnosticSource
    ) -> FormulaPlotDiagnostic {
        let severity: FormulaPlotDiagnosticSeverity = switch issue.kind {
        case .unsupportedIntent:
            .error
        case .invalidRange, .evaluationUndefined, .nonFinitePoint:
            .warning
        case .insufficientSamples, .possibleDiscontinuity:
            .info
        }
        return FormulaPlotDiagnostic(
            stage: .sampling,
            severity: severity,
            code: issue.kind.rawValue,
            message: issue.message,
            source: source
        )
    }

    private static func fromExprSeverity(_ severity: ExprDiagnosticSeverity) -> FormulaPlotDiagnosticSeverity {
        switch severity {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        }
    }

    private static func fromGraphSeverity(_ severity: GraphDiagnosticSeverity) -> FormulaPlotDiagnosticSeverity {
        switch severity {
        case .error: return .error
        case .warning: return .warning
        case .info: return .info
        }
    }
}

