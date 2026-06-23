public struct CanonicalRelation: Codable, Hashable, Equatable, Sendable {
    public var left: CanonicalExpr
    public var relation: RelationOperator
    public var right: CanonicalExpr

    public init(left: CanonicalExpr, relation: RelationOperator, right: CanonicalExpr) {
        self.left = left
        self.relation = relation
        self.right = right
    }
}

public struct CanonicalPiecewiseBranch: Codable, Hashable, Equatable, Sendable {
    public var value: CanonicalExpr
    public var condition: CanonicalExpr

    public init(value: CanonicalExpr, condition: CanonicalExpr) {
        self.value = value
        self.condition = condition
    }
}

public indirect enum CanonicalExpr: Codable, Hashable, Equatable, Sendable {
    case integer(Int)
    case rational(numerator: Int, denominator: Int)
    case decimal(String)
    case real(Double)
    case symbol(Symbol)
    case constant(MathConstant)

    case sum([CanonicalExpr])
    case product([CanonicalExpr])
    case power(base: CanonicalExpr, exponent: CanonicalExpr)
    case function(MathFunction, arguments: [CanonicalExpr])

    case relation(CanonicalRelation)
    case piecewise(branches: [CanonicalPiecewiseBranch], otherwise: CanonicalExpr?)

    case unknown(String)
}
