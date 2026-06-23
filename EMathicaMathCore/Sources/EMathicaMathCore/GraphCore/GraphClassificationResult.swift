public struct GraphClassificationResult: Equatable, Sendable {
    public var intent: GraphIntent
    public var diagnostics: [GraphDiagnostic]

    public init(intent: GraphIntent, diagnostics: [GraphDiagnostic] = []) {
        self.intent = intent
        self.diagnostics = diagnostics
    }
}

public struct GraphDiagnostic: Equatable, Sendable {
    public var severity: GraphDiagnosticSeverity
    public var code: GraphDiagnosticCode
    public var message: String

    public init(severity: GraphDiagnosticSeverity, code: GraphDiagnosticCode, message: String) {
        self.severity = severity
        self.code = code
        self.message = message
    }
}

public enum GraphDiagnosticSeverity: String, Codable, Equatable, Sendable {
    case info
    case warning
    case error
}

public enum GraphDiagnosticCode: String, Codable, Equatable, Sendable {
    case unsupportedExpression
    case ambiguousVariables
    case missingVariable
    case unsupportedRelation
    case unsupportedParametricForm
    case unsupportedPiecewiseBranch
}
