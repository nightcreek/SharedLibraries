public struct ExprDiagnostic: Codable, Equatable, Sendable {
    public var severity: ExprDiagnosticSeverity
    public var code: ExprDiagnosticCode
    public var message: String
    public var location: ExprSourceLocation?

    public init(
        severity: ExprDiagnosticSeverity,
        code: ExprDiagnosticCode,
        message: String,
        location: ExprSourceLocation? = nil
    ) {
        self.severity = severity
        self.code = code
        self.message = message
        self.location = location
    }
}

public enum ExprDiagnosticSeverity: String, Codable, Hashable, Equatable, Sendable {
    case info
    case warning
    case error
}

public enum ExprDiagnosticCode: String, Codable, Hashable, Equatable, Sendable {
    case emptyExpression
    case unresolvedPlaceholder
    case missingOperand
    case missingArgument
    case invalidFunctionArity
    case unsupportedEditorNode
    case unsupportedExpression
    case invalidNumberLiteral
    case unknownSymbol
    case unsupportedQuadraticTerm
    case unsupportedCoefficient
    case degreeTooHigh
    case unexpectedSymbol
    case expansionDegreeTooHigh
    case expansionTermLimitExceeded
    case unsupportedPolynomialFactor
    case unsupportedPolynomialVariable
    case nonNumericCoefficient
    case variableDenominator
}

public struct ExprSourceLocation: Codable, Hashable, Equatable, Sendable {
    public var editorNodeID: String?
    public var path: ExprPath?

    public init(editorNodeID: String? = nil, path: ExprPath? = nil) {
        self.editorNodeID = editorNodeID
        self.path = path
    }
}

public struct ExprPath: Codable, Hashable, Equatable, Sendable {
    public var components: [ExprPathComponent]

    public init(components: [ExprPathComponent] = []) {
        self.components = components
    }
}

public enum ExprPathComponent: Codable, Hashable, Equatable, Sendable {
    case index(Int)
    case field(String)
    case key(String)
}
