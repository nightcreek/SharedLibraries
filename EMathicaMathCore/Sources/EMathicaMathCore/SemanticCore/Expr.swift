public enum MathConstant: String, Codable, Hashable, Equatable, Sendable {
    case pi
    case e
    case imaginaryUnit
    case infinity
}

public indirect enum Expr: Codable, Equatable, Sendable {
    case integer(Int)
    case rational(numerator: Int, denominator: Int)
    case decimal(String)
    case real(Double)
    case symbol(Symbol)
    case constant(MathConstant)

    case add([Expr])
    case multiply([Expr])
    case power(base: Expr, exponent: Expr)
    case negate(Expr)
    case divide(numerator: Expr, denominator: Expr)

    case function(MathFunction, arguments: [Expr])

    case equation(left: Expr, right: Expr)
    case relation(left: Expr, relation: RelationOperator, right: Expr)
    case chainedRelation(expressions: [Expr], relations: [RelationOperator])

    case piecewise(branches: [PiecewiseBranch], otherwise: Expr?)

    case tuple([Expr])
    case vector([Expr])
    case matrix(MatrixExpr)

    case assignment(target: Expr, value: Expr)
    case functionDefinition(name: Symbol, parameters: [Symbol], body: Expr)

    case unknown(String)
}
