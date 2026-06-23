import Foundation

public indirect enum AlgebraExpression: Hashable, Codable {
    case number(Double)
    case symbol(String)
    case add([AlgebraExpression])
    case multiply([AlgebraExpression])
    case divide(AlgebraExpression, AlgebraExpression)
    case power(AlgebraExpression, AlgebraExpression)
    case function(String, AlgebraExpression)

    public var symbols: Set<String> {
        switch self {
        case .number:
            return []
        case .symbol(let name):
            return [name]
        case .add(let terms), .multiply(let terms):
            return terms.reduce(into: Set<String>()) { $0.formUnion($1.symbols) }
        case .divide(let lhs, let rhs), .power(let lhs, let rhs):
            return lhs.symbols.union(rhs.symbols)
        case .function(_, let argument):
            return argument.symbols
        }
    }
}

public struct AlgebraEquation: Hashable, Codable {
    public var left: AlgebraExpression
    public var right: AlgebraExpression
}

public enum AlgebraRelation: Hashable, Codable {
    case expression(AlgebraExpression)
    case equation(AlgebraEquation)
}

// MARK: - AlgebraExpression → Expr bridge

/// Temporary bridge from parser AST (AlgebraExpression) to semantic CAS AST (Expr).
///
/// This bridge exists because the current Plane input pipeline parses LaTeX into
/// AlgebraExpression (via `AlgebraCore.analyzePlaneLatex`), but CAS operations
/// (differentiation, simplification, evaluation) operate on `Expr`.
///
/// **This is NOT a permanent API.** When the parser is unified to produce `Expr`
/// directly, this bridge should be removed. Do not build new features that depend
/// on AlgebraExpression → Expr → AlgebraExpression round trips.
extension AlgebraExpression {
    public func toSemanticExpr() -> Expr {
        switch self {
        case .number(let value):
            if value == Double(Int(value)) {
                return .integer(Int(value))
            }
            return .real(value)
        case .symbol(let name):
            return .symbol(Symbol(name: name))
        case .add(let terms):
            return .add(terms.map { $0.toSemanticExpr() })
        case .multiply(let factors):
            return .multiply(factors.map { $0.toSemanticExpr() })
        case .divide(let num, let den):
            return .divide(numerator: num.toSemanticExpr(), denominator: den.toSemanticExpr())
        case .power(let base, let exp):
            return .power(base: base.toSemanticExpr(), exponent: exp.toSemanticExpr())
        case .function(let name, let arg):
            if let fn = MathFunction(name) {
                return .function(fn, arguments: [arg.toSemanticExpr()])
            }
            return .function(.custom(name), arguments: [arg.toSemanticExpr()])
        }
    }
}


