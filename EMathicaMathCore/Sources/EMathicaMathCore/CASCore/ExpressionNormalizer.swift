public struct ExpressionNormalizer {
    public init() {}

    public func normalize(_ expr: Expr) -> Expr {
        switch expr {
        case .add(let terms):
            let normalizedTerms = terms.map(normalize)
            let flattened = normalizedTerms.flatMap { term -> [Expr] in
                if case .add(let inner) = term { return inner }
                return [term]
            }
            if flattened.isEmpty {
                // Defensive fallback for malformed AST.
                return .integer(0)
            }
            if flattened.count == 1 {
                return flattened[0]
            }
            return .add(flattened)

        case .multiply(let factors):
            let normalizedFactors = factors.map(normalize)
            let flattened = normalizedFactors.flatMap { factor -> [Expr] in
                if case .multiply(let inner) = factor { return inner }
                return [factor]
            }
            if flattened.isEmpty {
                // Defensive fallback for malformed AST.
                return .integer(1)
            }
            if flattened.count == 1 {
                return flattened[0]
            }
            return .multiply(flattened)

        case .power(let base, let exponent):
            return .power(base: normalize(base), exponent: normalize(exponent))
        case .negate(let value):
            return .negate(normalize(value))
        case .divide(let numerator, let denominator):
            return .divide(numerator: normalize(numerator), denominator: normalize(denominator))
        case .function(let fn, let arguments):
            return .function(fn, arguments: arguments.map(normalize))

        case .equation(let left, let right):
            return .equation(left: normalize(left), right: normalize(right))
        case .relation(let left, let relation, let right):
            return .relation(left: normalize(left), relation: relation, right: normalize(right))
        case .chainedRelation(let expressions, let relations):
            return .chainedRelation(expressions: expressions.map(normalize), relations: relations)

        case .piecewise(let branches, let otherwise):
            let normalizedBranches = branches.map {
                PiecewiseBranch(value: normalize($0.value), condition: normalize($0.condition))
            }
            return .piecewise(branches: normalizedBranches, otherwise: otherwise.map(normalize))

        case .tuple(let values):
            return .tuple(values.map(normalize))
        case .vector(let values):
            return .vector(values.map(normalize))
        case .matrix(let matrix):
            return .matrix(MatrixExpr(rows: matrix.rows.map { $0.map(normalize) }))

        case .assignment(let target, let value):
            return .assignment(target: normalize(target), value: normalize(value))
        case .functionDefinition(let name, let parameters, let body):
            return .functionDefinition(name: name, parameters: parameters, body: normalize(body))

        case .integer, .rational, .decimal, .real, .symbol, .constant, .unknown:
            return expr
        }
    }
}
