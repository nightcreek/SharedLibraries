import Foundation

public struct PolynomialExpansionOptions: Equatable, Sendable {
    public var maxDegree: Int
    public var maxTermCount: Int
    public var allowedVariables: Set<Symbol>

    public init(
        maxDegree: Int,
        maxTermCount: Int,
        allowedVariables: Set<Symbol>
    ) {
        self.maxDegree = maxDegree
        self.maxTermCount = maxTermCount
        self.allowedVariables = allowedVariables
    }

    public static let default2D = PolynomialExpansionOptions(
        maxDegree: 2,
        maxTermCount: 16,
        allowedVariables: [
            Symbol(name: "x", role: .variable),
            Symbol(name: "y", role: .variable)
        ]
    )
}

public struct QuadraticPolynomial2D: Equatable, Sendable {
    public var xx: Double
    public var xy: Double
    public var yy: Double
    public var x: Double
    public var y: Double
    public var constant: Double

    public init(
        xx: Double = 0,
        xy: Double = 0,
        yy: Double = 0,
        x: Double = 0,
        y: Double = 0,
        constant: Double = 0
    ) {
        self.xx = xx
        self.xy = xy
        self.yy = yy
        self.x = x
        self.y = y
        self.constant = constant
    }

    fileprivate static let epsilon = 1e-12

    fileprivate var degree: Int {
        if abs(xx) > Self.epsilon || abs(xy) > Self.epsilon || abs(yy) > Self.epsilon { return 2 }
        if abs(x) > Self.epsilon || abs(y) > Self.epsilon { return 1 }
        return 0
    }

    fileprivate var termCount: Int {
        var count = 0
        if abs(xx) > Self.epsilon { count += 1 }
        if abs(xy) > Self.epsilon { count += 1 }
        if abs(yy) > Self.epsilon { count += 1 }
        if abs(x) > Self.epsilon { count += 1 }
        if abs(y) > Self.epsilon { count += 1 }
        if abs(constant) > Self.epsilon { count += 1 }
        return count
    }

    fileprivate func adding(_ rhs: QuadraticPolynomial2D) -> QuadraticPolynomial2D {
        QuadraticPolynomial2D(
            xx: xx + rhs.xx,
            xy: xy + rhs.xy,
            yy: yy + rhs.yy,
            x: x + rhs.x,
            y: y + rhs.y,
            constant: constant + rhs.constant
        )
    }

    fileprivate func negated() -> QuadraticPolynomial2D {
        QuadraticPolynomial2D(
            xx: -xx,
            xy: -xy,
            yy: -yy,
            x: -x,
            y: -y,
            constant: -constant
        )
    }

    fileprivate func divided(by scalar: Double) -> QuadraticPolynomial2D {
        QuadraticPolynomial2D(
            xx: xx / scalar,
            xy: xy / scalar,
            yy: yy / scalar,
            x: x / scalar,
            y: y / scalar,
            constant: constant / scalar
        )
    }

    fileprivate func multiplied(by rhs: QuadraticPolynomial2D) -> QuadraticPolynomial2D {
        // (a2x^2 + a1x + ... ) * (b2x^2 + b1x + ...), truncated only by caller checks.
        var result = QuadraticPolynomial2D()

        let lhsTerms = monomials()
        let rhsTerms = rhs.monomials()

        for (lx, ly, lc) in lhsTerms {
            for (rx, ry, rc) in rhsTerms {
                let nx = lx + rx
                let ny = ly + ry
                let coeff = lc * rc
                switch (nx, ny) {
                case (2, 0):
                    result.xx += coeff
                case (1, 1):
                    result.xy += coeff
                case (0, 2):
                    result.yy += coeff
                case (1, 0):
                    result.x += coeff
                case (0, 1):
                    result.y += coeff
                case (0, 0):
                    result.constant += coeff
                default:
                    // Caller enforces degree <= 2.
                    break
                }
            }
        }
        return result
    }

    fileprivate func monomials() -> [(Int, Int, Double)] {
        var result: [(Int, Int, Double)] = []
        if abs(xx) > Self.epsilon { result.append((2, 0, xx)) }
        if abs(xy) > Self.epsilon { result.append((1, 1, xy)) }
        if abs(yy) > Self.epsilon { result.append((0, 2, yy)) }
        if abs(x) > Self.epsilon { result.append((1, 0, x)) }
        if abs(y) > Self.epsilon { result.append((0, 1, y)) }
        if abs(constant) > Self.epsilon { result.append((0, 0, constant)) }
        if result.isEmpty { result.append((0, 0, 0)) }
        return result
    }

    fileprivate func toExpr() -> Expr {
        var terms: [Expr] = []

        appendTerm(coefficient: xx, xDegree: 2, yDegree: 0, into: &terms)
        appendTerm(coefficient: xy, xDegree: 1, yDegree: 1, into: &terms)
        appendTerm(coefficient: yy, xDegree: 0, yDegree: 2, into: &terms)
        appendTerm(coefficient: x, xDegree: 1, yDegree: 0, into: &terms)
        appendTerm(coefficient: y, xDegree: 0, yDegree: 1, into: &terms)
        appendTerm(coefficient: constant, xDegree: 0, yDegree: 0, into: &terms)

        if terms.isEmpty { return .integer(0) }
        if terms.count == 1 { return terms[0] }
        return .add(terms)
    }

    private func appendTerm(
        coefficient: Double,
        xDegree: Int,
        yDegree: Int,
        into terms: inout [Expr]
    ) {
        guard abs(coefficient) > Self.epsilon else { return }

        let monomial = makeMonomial(xDegree: xDegree, yDegree: yDegree)
        if xDegree == 0 && yDegree == 0 {
            terms.append(makeNumberExpr(coefficient))
            return
        }

        if abs(coefficient - 1.0) <= Self.epsilon {
            terms.append(monomial)
            return
        }
        if abs(coefficient + 1.0) <= Self.epsilon {
            terms.append(.negate(monomial))
            return
        }
        terms.append(.multiply([makeNumberExpr(coefficient), monomial]))
    }

    private func makeMonomial(xDegree: Int, yDegree: Int) -> Expr {
        var factors: [Expr] = []
        let xSym = Expr.symbol(Symbol(name: "x", role: .variable))
        let ySym = Expr.symbol(Symbol(name: "y", role: .variable))

        if xDegree == 1 {
            factors.append(xSym)
        } else if xDegree == 2 {
            factors.append(.power(base: xSym, exponent: .integer(2)))
        }
        if yDegree == 1 {
            factors.append(ySym)
        } else if yDegree == 2 {
            factors.append(.power(base: ySym, exponent: .integer(2)))
        }

        if factors.isEmpty { return .integer(1) }
        if factors.count == 1 { return factors[0] }
        return .multiply(factors)
    }

    private func makeNumberExpr(_ value: Double) -> Expr {
        let rounded = value.rounded()
        if abs(value - rounded) <= Self.epsilon,
           rounded <= Double(Int.max),
           rounded >= Double(Int.min) {
            return .integer(Int(rounded))
        }
        return .real(value)
    }
}

public struct PolynomialExpander {
    private let normalizer: ExpressionNormalizer
    private let simplifier: ExpressionSimplifier
    private let evaluator: ExprEvaluator

    public init(
        normalizer: ExpressionNormalizer = .init(),
        simplifier: ExpressionSimplifier = .init(),
        evaluator: ExprEvaluator = .init()
    ) {
        self.normalizer = normalizer
        self.simplifier = simplifier
        self.evaluator = evaluator
    }

    public func expand(
        _ expr: Expr,
        options: PolynomialExpansionOptions = .default2D
    ) -> Result<Expr, ExprDiagnosticList> {
        let normalized = simplifier.simplify(normalizer.normalize(expr))
        switch polynomial(from: normalized, options: options) {
        case .success(let poly):
            return .success(poly.toExpr())
        case .failure(let diagnostics):
            return .failure(diagnostics)
        }
    }

    private func polynomial(
        from expr: Expr,
        options: PolynomialExpansionOptions
    ) -> Result<QuadraticPolynomial2D, ExprDiagnosticList> {
        switch expr {
        case .integer(let value):
            return checked(QuadraticPolynomial2D(constant: Double(value)), options: options)
        case .rational(let n, let d):
            guard d != 0 else {
                return .failure(diagnostic(.nonNumericCoefficient, "rational denominator cannot be zero"))
            }
            return checked(QuadraticPolynomial2D(constant: Double(n) / Double(d)), options: options)
        case .decimal(let raw):
            guard let value = Double(raw), value.isFinite else {
                return .failure(diagnostic(.nonNumericCoefficient, "invalid decimal coefficient: \(raw)"))
            }
            return checked(QuadraticPolynomial2D(constant: value), options: options)
        case .real(let value):
            guard value.isFinite else {
                return .failure(diagnostic(.nonNumericCoefficient, "non-finite real coefficient"))
            }
            return checked(QuadraticPolynomial2D(constant: value), options: options)
        case .constant:
            return .failure(diagnostic(.nonNumericCoefficient, "symbolic constants are not supported in finite expansion"))

        case .symbol(let symbol):
            return polynomialFromSymbol(symbol, options: options)

        case .power(let base, let exponent):
            guard case .integer(let degree) = exponent else {
                return .failure(diagnostic(.unsupportedPolynomialFactor, "power exponent must be integer 0/1/2"))
            }
            switch degree {
            case 0:
                return .success(.init(constant: 1))
            case 1:
                return polynomial(from: base, options: options)
            case 2:
                switch polynomial(from: base, options: options) {
                case .success(let p):
                    return multiply(p, p, options: options)
                case .failure(let d):
                    return .failure(d)
                }
            default:
                return .failure(diagnostic(.expansionDegreeTooHigh, "power degree \(degree) exceeds limit"))
            }

        case .add(let terms):
            var acc = QuadraticPolynomial2D()
            for term in terms {
                switch polynomial(from: term, options: options) {
                case .success(let p):
                    acc = acc.adding(p)
                    switch checked(acc, options: options) {
                    case .success(let checkedPoly):
                        acc = checkedPoly
                    case .failure(let d):
                        return .failure(d)
                    }
                case .failure(let d):
                    return .failure(d)
                }
            }
            return .success(acc)

        case .multiply(let factors):
            var acc = QuadraticPolynomial2D(constant: 1)
            for factor in factors {
                switch polynomial(from: factor, options: options) {
                case .success(let p):
                    switch multiply(acc, p, options: options) {
                    case .success(let product):
                        acc = product
                    case .failure(let d):
                        return .failure(d)
                    }
                case .failure(let d):
                    return .failure(d)
                }
            }
            return .success(acc)

        case .negate(let inner):
            switch polynomial(from: inner, options: options) {
            case .success(let p):
                return .success(p.negated())
            case .failure(let d):
                return .failure(d)
            }

        case .divide(let numerator, let denominator):
            switch polynomial(from: numerator, options: options) {
            case .failure(let d):
                return .failure(d)
            case .success(let p):
                if containsAllowedVariable(denominator, options: options) {
                    return .failure(diagnostic(.variableDenominator, "denominator cannot contain polynomial variables"))
                }
                guard let scalar = evaluateNumeric(denominator), abs(scalar) > 1e-12 else {
                    return .failure(diagnostic(.nonNumericCoefficient, "denominator must be non-zero numeric scalar"))
                }
                return checked(p.divided(by: scalar), options: options)
            }

        case .function:
            return .failure(diagnostic(.unsupportedPolynomialFactor, "function term is not supported"))

        case .equation, .relation, .chainedRelation:
            return .failure(diagnostic(.unsupportedExpression, "equation/relation expansion is not supported here"))

        case .piecewise, .tuple, .vector, .matrix, .assignment, .functionDefinition, .unknown:
            return .failure(diagnostic(.unsupportedExpression, "expression kind is not supported for polynomial expansion"))
        }
    }

    private func polynomialFromSymbol(
        _ symbol: Symbol,
        options: PolynomialExpansionOptions
    ) -> Result<QuadraticPolynomial2D, ExprDiagnosticList> {
        let allowedNames = Set(options.allowedVariables.map(\.name))
        guard allowedNames.contains(symbol.name) else {
            return .failure(diagnostic(.unsupportedPolynomialVariable, "unsupported polynomial variable: \(symbol.name)"))
        }

        switch symbol.name {
        case "x":
            return .success(QuadraticPolynomial2D(x: 1))
        case "y":
            return .success(QuadraticPolynomial2D(y: 1))
        default:
            return .failure(diagnostic(.unsupportedPolynomialVariable, "only x/y variables are supported in 2D quadratic expansion"))
        }
    }

    private func multiply(
        _ lhs: QuadraticPolynomial2D,
        _ rhs: QuadraticPolynomial2D,
        options: PolynomialExpansionOptions
    ) -> Result<QuadraticPolynomial2D, ExprDiagnosticList> {
        var result = QuadraticPolynomial2D()
        for (lx, ly, lc) in lhs.monomials() {
            for (rx, ry, rc) in rhs.monomials() {
                let nx = lx + rx
                let ny = ly + ry
                let totalDegree = nx + ny
                if totalDegree > options.maxDegree {
                    return .failure(diagnostic(
                        .expansionDegreeTooHigh,
                        "term degree \(totalDegree) exceeds maxDegree=\(options.maxDegree)"
                    ))
                }
                let coeff = lc * rc
                switch (nx, ny) {
                case (2, 0):
                    result.xx += coeff
                case (1, 1):
                    result.xy += coeff
                case (0, 2):
                    result.yy += coeff
                case (1, 0):
                    result.x += coeff
                case (0, 1):
                    result.y += coeff
                case (0, 0):
                    result.constant += coeff
                default:
                    return .failure(diagnostic(
                        .unsupportedPolynomialFactor,
                        "unsupported monomial degree (\(nx), \(ny)) in multiplication"
                    ))
                }
            }
        }
        return checked(result, options: options)
    }

    private func checked(
        _ polynomial: QuadraticPolynomial2D,
        options: PolynomialExpansionOptions
    ) -> Result<QuadraticPolynomial2D, ExprDiagnosticList> {
        if polynomial.degree > options.maxDegree {
            return .failure(diagnostic(
                .expansionDegreeTooHigh,
                "polynomial degree \(polynomial.degree) exceeds maxDegree=\(options.maxDegree)"
            ))
        }
        if polynomial.termCount > options.maxTermCount {
            return .failure(diagnostic(
                .expansionTermLimitExceeded,
                "polynomial term count \(polynomial.termCount) exceeds maxTermCount=\(options.maxTermCount)"
            ))
        }
        return .success(polynomial)
    }

    private func containsAllowedVariable(_ expr: Expr, options: PolynomialExpansionOptions) -> Bool {
        let allowedNames = Set(options.allowedVariables.map(\.name))
        switch expr {
        case .symbol(let symbol):
            return allowedNames.contains(symbol.name)
        case .add(let terms):
            return terms.contains(where: { containsAllowedVariable($0, options: options) })
        case .multiply(let factors):
            return factors.contains(where: { containsAllowedVariable($0, options: options) })
        case .power(let base, _):
            return containsAllowedVariable(base, options: options)
        case .negate(let value):
            return containsAllowedVariable(value, options: options)
        case .divide(let n, let d):
            return containsAllowedVariable(n, options: options) || containsAllowedVariable(d, options: options)
        case .function(_, let args):
            return args.contains(where: { containsAllowedVariable($0, options: options) })
        case .piecewise(let branches, let otherwise):
            return branches.contains(where: { containsAllowedVariable($0.value, options: options) || containsAllowedVariable($0.condition, options: options) })
                || otherwise.map { containsAllowedVariable($0, options: options) } ?? false
        case .tuple(let values), .vector(let values):
            return values.contains(where: { containsAllowedVariable($0, options: options) })
        case .matrix(let matrix):
            return matrix.rows.flatMap { $0 }.contains(where: { containsAllowedVariable($0, options: options) })
        case .equation(let l, let r):
            return containsAllowedVariable(l, options: options) || containsAllowedVariable(r, options: options)
        case .relation(let l, _, let r):
            return containsAllowedVariable(l, options: options) || containsAllowedVariable(r, options: options)
        case .chainedRelation(let expressions, _):
            return expressions.contains(where: { containsAllowedVariable($0, options: options) })
        case .assignment(let target, let value):
            return containsAllowedVariable(target, options: options) || containsAllowedVariable(value, options: options)
        case .functionDefinition(_, _, let body):
            return containsAllowedVariable(body, options: options)
        case .integer, .rational, .decimal, .real, .constant, .unknown:
            return false
        }
    }

    private func evaluateNumeric(_ expr: Expr) -> Double? {
        switch evaluator.evaluate(expr, environment: .init()) {
        case .value(let value) where value.isFinite:
            return value
        default:
            return nil
        }
    }

    private func diagnostic(_ code: ExprDiagnosticCode, _ message: String) -> ExprDiagnosticList {
        ExprDiagnosticList([
            ExprDiagnostic(
                severity: .error,
                code: code,
                message: message,
                location: nil
            )
        ])
    }
}
