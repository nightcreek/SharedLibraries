public struct Canonicalizer {
    private let normalizer: ExpressionNormalizer
    private let simplifier: ExpressionSimplifier

    public init(
        normalizer: ExpressionNormalizer = .init(),
        simplifier: ExpressionSimplifier = .init()
    ) {
        self.normalizer = normalizer
        self.simplifier = simplifier
    }

    public func canonicalize(_ expr: Expr) -> CanonicalExpr {
        let normalized = normalizer.normalize(expr)
        let simplified = simplifier.simplify(normalized)
        return toCanonical(simplified)
    }

    private func toCanonical(_ expr: Expr) -> CanonicalExpr {
        switch expr {
        case .integer(let value):
            return .integer(value)
        case .rational(let numerator, let denominator):
            return .rational(numerator: numerator, denominator: denominator)
        case .decimal(let value):
            return .decimal(value)
        case .real(let value):
            return .real(value)
        case .symbol(let symbol):
            return .symbol(symbol)
        case .constant(let constant):
            return .constant(constant)
        case .add(let terms):
            return .sum(terms.map(toCanonical))
        case .multiply(let factors):
            return .product(factors.map(toCanonical))
        case .power(let base, let exponent):
            return .power(base: toCanonical(base), exponent: toCanonical(exponent))
        case .function(let fn, let arguments):
            return .function(fn, arguments: arguments.map(toCanonical))
        case .equation(let left, let right):
            return .relation(CanonicalRelation(
                left: toCanonical(left),
                relation: .equal,
                right: toCanonical(right)
            ))
        case .relation(let left, let relation, let right):
            return .relation(CanonicalRelation(
                left: toCanonical(left),
                relation: relation,
                right: toCanonical(right)
            ))
        case .piecewise(let branches, let otherwise):
            let canonicalBranches = branches.map {
                CanonicalPiecewiseBranch(value: toCanonical($0.value), condition: toCanonical($0.condition))
            }
            return .piecewise(branches: canonicalBranches, otherwise: otherwise.map(toCanonical))

        case .negate(let value):
            return .product([.integer(-1), toCanonical(value)])
        case .divide(let numerator, let denominator):
            return .product([
                toCanonical(numerator),
                .power(base: toCanonical(denominator), exponent: .integer(-1))
            ])
        case .chainedRelation:
            return .unknown("chainedRelation")
        case .tuple:
            return .unknown("tuple")
        case .vector:
            return .unknown("vector")
        case .matrix:
            return .unknown("matrix")
        case .assignment:
            return .unknown("assignment")
        case .functionDefinition:
            return .unknown("functionDefinition")
        case .unknown(let value):
            return .unknown(value)
        }
    }
}
