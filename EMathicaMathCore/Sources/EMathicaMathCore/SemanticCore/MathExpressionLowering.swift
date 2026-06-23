public enum LoweringMode: String, Codable, Hashable, Equatable, Sendable {
    case expression
    case objectDefinition
    case equationInput
    case condition
}

public struct SymbolTable: Codable, Equatable, Sendable {
    public var symbols: [String: Symbol]

    public init(symbols: [String: Symbol] = [:]) {
        self.symbols = symbols
    }

    public func symbol(named name: String) -> Symbol? {
        symbols[name]
    }
}

public struct LoweringContext: Codable, Equatable, Sendable {
    public var mode: LoweringMode
    public var symbolTable: SymbolTable

    public init(
        mode: LoweringMode = .expression,
        symbolTable: SymbolTable = SymbolTable()
    ) {
        self.mode = mode
        self.symbolTable = symbolTable
    }
}

public struct LoweringResult: Codable, Equatable, Sendable {
    public var expr: Expr?
    public var diagnostics: [ExprDiagnostic]
    public var sourceMap: [ExprPath: ExprSourceLocation]
    public var succeeded: Bool

    public init(
        expr: Expr? = nil,
        diagnostics: [ExprDiagnostic] = [],
        sourceMap: [ExprPath: ExprSourceLocation] = [:],
        succeeded: Bool
    ) {
        self.expr = expr
        self.diagnostics = diagnostics
        self.sourceMap = sourceMap
        self.succeeded = succeeded
    }
}
