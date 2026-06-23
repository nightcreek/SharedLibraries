public struct ExpressionSimplifier {
    public init() {}

    public func simplify(_ expr: Expr) -> Expr {
        switch expr {
        case .add(let terms):
            return simplifyAdd(terms.map(simplify))
        case .multiply(let factors):
            return simplifyMultiply(factors.map(simplify))
        case .power(let base, let exponent):
            let b = simplify(base)
            let e = simplify(exponent)
            if case .integer(1) = e { return b }
            if case .integer(0) = e { return .integer(1) }
            return .power(base: b, exponent: e)
        case .negate(let value):
            let simplified = simplify(value)
            if case .negate(let inner) = simplified {
                return inner
            }
            return .negate(simplified)
        case .divide(let numerator, let denominator):
            let n = simplify(numerator)
            let d = simplify(denominator)
            if case .integer(let a) = n, case .integer(let b) = d, b != 0 {
                return simplifyRational(numerator: a, denominator: b)
            }
            return .divide(numerator: n, denominator: d)
        case .rational(let numerator, let denominator):
            return simplifyRational(numerator: numerator, denominator: denominator)

        case .function(let fn, let arguments):
            return .function(fn, arguments: arguments.map(simplify))
        case .equation(let left, let right):
            return .equation(left: simplify(left), right: simplify(right))
        case .relation(let left, let relation, let right):
            return .relation(left: simplify(left), relation: relation, right: simplify(right))
        case .chainedRelation(let expressions, let relations):
            return .chainedRelation(expressions: expressions.map(simplify), relations: relations)
        case .piecewise(let branches, let otherwise):
            let mapped = branches.map { PiecewiseBranch(value: simplify($0.value), condition: simplify($0.condition)) }
            return .piecewise(branches: mapped, otherwise: otherwise.map(simplify))
        case .tuple(let values):
            return .tuple(values.map(simplify))
        case .vector(let values):
            return .vector(values.map(simplify))
        case .matrix(let matrix):
            return .matrix(MatrixExpr(rows: matrix.rows.map { $0.map(simplify) }))
        case .assignment(let target, let value):
            return .assignment(target: simplify(target), value: simplify(value))
        case .functionDefinition(let name, let parameters, let body):
            return .functionDefinition(name: name, parameters: parameters, body: simplify(body))

        case .integer, .decimal, .real, .symbol, .constant, .unknown:
            return expr
        }
    }

    private func simplifyAdd(_ terms: [Expr]) -> Expr {
        var filtered: [Expr] = []
        var integerSum = 0

        for term in terms {
            switch term {
            case .integer(let value):
                integerSum += value
            case .add(let nested):
                for nestedTerm in nested {
                    if case .integer(let value) = nestedTerm {
                        integerSum += value
                    } else if !isZero(nestedTerm) {
                        filtered.append(nestedTerm)
                    }
                }
            default:
                if !isZero(term) {
                    filtered.append(term)
                }
            }
        }

        if integerSum != 0 {
            filtered.insert(.integer(integerSum), at: 0)
        }
        if filtered.isEmpty { return .integer(0) }
        if filtered.count == 1 { return filtered[0] }
        return .add(filtered)
    }

    private func simplifyMultiply(_ factors: [Expr]) -> Expr {
        var filtered: [Expr] = []
        var integerProduct = 1
        var hasInteger = false

        for factor in factors {
            switch factor {
            case .integer(let value):
                hasInteger = true
                if value == 0 { return .integer(0) }
                integerProduct *= value
            case .multiply(let nested):
                for nestedFactor in nested {
                    if case .integer(let value) = nestedFactor {
                        hasInteger = true
                        if value == 0 { return .integer(0) }
                        integerProduct *= value
                    } else if !isOne(nestedFactor) {
                        filtered.append(nestedFactor)
                    }
                }
            default:
                if isZero(factor) { return .integer(0) }
                if !isOne(factor) {
                    filtered.append(factor)
                }
            }
        }

        if hasInteger && integerProduct != 1 {
            filtered.insert(.integer(integerProduct), at: 0)
        }
        if filtered.isEmpty {
            return hasInteger ? .integer(integerProduct) : .integer(1)
        }
        if filtered.count == 1 {
            return filtered[0]
        }
        return .multiply(filtered)
    }

    private func simplifyRational(numerator: Int, denominator: Int) -> Expr {
        if denominator == 0 {
            return .rational(numerator: numerator, denominator: denominator)
        }
        if numerator == 0 {
            return .integer(0)
        }

        var n = numerator
        var d = denominator
        if d < 0 {
            n = -n
            d = -d
        }
        let divisor = gcd(abs(n), d)
        n /= divisor
        d /= divisor

        if d == 1 {
            return .integer(n)
        }
        return .rational(numerator: n, denominator: d)
    }

    private func gcd(_ a: Int, _ b: Int) -> Int {
        var x = a
        var y = b
        while y != 0 {
            let r = x % y
            x = y
            y = r
        }
        return max(1, x)
    }

    private func isZero(_ expr: Expr) -> Bool {
        switch expr {
        case .integer(0): return true
        case .rational(let n, _) where n == 0: return true
        default: return false
        }
    }

    private func isOne(_ expr: Expr) -> Bool {
        switch expr {
        case .integer(1): return true
        case .rational(let n, let d) where n == d: return true
        default: return false
        }
    }
}
