import Foundation

// MARK: - Result Types

/// The complete result of an equation solving attempt.
public struct EquationSolutionSet: Equatable, Sendable {
    public var solutions: [EquationSolution]
    public var diagnostics: [SolveDiagnostic]

    public init(solutions: [EquationSolution] = [], diagnostics: [SolveDiagnostic] = []) {
        self.solutions = solutions
        self.diagnostics = diagnostics
    }

    public var hasSolutions: Bool { !solutions.isEmpty }
    public var hasExactSolutions: Bool { solutions.contains { if case .exact = $0 { return true }; return false } }
}

/// A single solution to an equation.
public enum EquationSolution: Equatable, Sendable {
    /// Exact symbolic solution, e.g. x = 2, x = -b/(2a).
    case exact(value: Expr)
    /// Numeric approximation, e.g. x ≈ 1.414.
    case numeric(value: Double, tolerance: Double)
}

/// Why a solve attempt produced no useful result.
public enum SolveDiagnostic: Equatable, Sendable {
    case noRealSolution
    case infiniteSolutions
    case unsupported(String)
    case notAUnivariateEquation
    case extractionFailed(String)
    case numericDidNotConverge
}

// MARK: - Solver

/// Symbolic and numeric equation solving for univariate equations.
/// Operates purely on MathCore types — no Plane/Workspace/Document dependencies.
public enum EquationSolver {

    // MARK: - Public API

    /// Solve an equation for the given variable.
    /// Automatically dispatches to linear, quadratic, or returns unsupported.
    public static func solve(_ equation: Expr, variable: Symbol) -> EquationSolutionSet {
        // Normalize: move everything to left side → expr = 0
        let normalized = normalizeEquation(equation)
        guard isUnivariate(normalized, variable: variable) else {
            return EquationSolutionSet(diagnostics: [.notAUnivariateEquation])
        }

        let simplifier = ExpressionSimplifier()
        let norm = ExpressionNormalizer()
        let expr = norm.normalize(simplifier.simplify(normalized))

        // Try quadratic first (most specific), then linear
        if let quadResult = solveQuadratic(expr, variable: variable) {
            return quadResult
        }
        if let linResult = solveLinear(expr, variable: variable) {
            return linResult
        }

        return EquationSolutionSet(diagnostics: [.unsupported("表达式不是一元线性或二次方程")])
    }

    // MARK: - Linear

    /// Solve ax + b = 0 for x. Returns nil if the expression is not linear.
    public static func solveLinear(_ expr: Expr, variable: Symbol) -> EquationSolutionSet? {
        // Try to extract a (coefficient of x) and b (constant)
        guard let (a, b) = extractLinearCoefficients(expr, variable: variable) else {
            return nil
        }

        // Check if a is effectively zero
        if isZero(a) {
            if isZero(b) {
                return EquationSolutionSet(diagnostics: [.infiniteSolutions])
            }
            return EquationSolutionSet(diagnostics: [.noRealSolution])
        }

        // x = -b / a
        let solution: Expr = .divide(
            numerator: .negate(b),
            denominator: a
        )
        let normalized = ExpressionNormalizer().normalize(ExpressionSimplifier().simplify(solution))
        return EquationSolutionSet(solutions: [.exact(value: normalized)])
    }

    // MARK: - Quadratic

    /// Solve ax² + bx + c = 0 for x. Returns nil if the expression is not quadratic.
    public static func solveQuadratic(_ expr: Expr, variable: Symbol) -> EquationSolutionSet? {
        let extractor = QuadraticFormExtractor()
        let options = QuadraticFormExtractionOptions.expanded2D
        guard case .success(let form) = extractor.extract(expr, options: options) else {
            return nil
        }

        // For univariate: xx = a, x = b, constant = c
        let a = form.xx
        let b = form.x
        let c = form.constant

        // Guard: if a is effectively zero, this is not a quadratic — let linear handle it
        guard abs(a) > 1e-12 else { return nil }

        let discriminant = b * b - 4 * a * c

        if discriminant < -1e-12 {
            return EquationSolutionSet(diagnostics: [.noRealSolution])
        }

        if abs(discriminant) <= 1e-12 {
            // Double root: x = -b / (2a)
            let root = -b / (2 * a)
            return EquationSolutionSet(solutions: [.numeric(value: root, tolerance: 1e-9)])
        }

        let sqrtD = sqrt(discriminant)
        let denom = 2 * a
        let x1 = (-b + sqrtD) / denom
        let x2 = (-b - sqrtD) / denom

        return EquationSolutionSet(solutions: [
            .numeric(value: x1, tolerance: 1e-9),
            .numeric(value: x2, tolerance: 1e-9)
        ])
    }

    // MARK: - Newton-Raphson Numeric Root Finding

    /// Find a root of f(x) = 0 near `initialGuess` using Newton-Raphson.
    /// Uses `SymbolicDifferentiator` for the derivative.
    /// Returns nil if the method fails to converge.
    public static func findRootNewton(
        _ expr: Expr,
        variable: Symbol,
        initialGuess: Double = 0,
        maxIterations: Int = 50,
        tolerance: Double = 1e-9
    ) -> Double? {
        guard let derivative = SymbolicDifferentiator.differentiate(expr, withRespectTo: variable) else {
            return nil
        }

        let evaluator = ExprEvaluator()
        var x = initialGuess

        for _ in 0..<maxIterations {
            let env = EvaluationEnvironment.variables([variable.name: x])
            let fResult = evaluator.evaluate(expr, environment: env)
            let dResult = evaluator.evaluate(derivative, environment: env)

            guard case .value(let fVal) = fResult, fVal.isFinite,
                  case .value(let dVal) = dResult, dVal.isFinite,
                  abs(dVal) > 1e-15 else {
                return nil
            }

            let delta = fVal / dVal
            x = x - delta

            if abs(delta) < tolerance {
                return x.isFinite ? x : nil
            }
        }

        return x.isFinite ? x : nil
    }

    // MARK: - Helpers

    /// Move all terms to left side: transform `lhs = rhs` → `lhs - rhs`, or
    /// if already a plain expression, return as-is (interpreted as `expr = 0`).
    private static func normalizeEquation(_ expr: Expr) -> Expr {
        switch expr {
        case .equation(let left, let right):
            return .add([left, .negate(right)])
        case .relation(let left, let op, let right):
            if op == .equal {
                return .add([left, .negate(right)])
            }
            return expr
        default:
            // Plain expression is treated as expr = 0
            return expr
        }
    }

    /// Check if the expression contains only the given variable (univariate check).
    private static func isUnivariate(_ expr: Expr, variable: Symbol) -> Bool {
        let symbols = collectSymbols(expr)
        return symbols.isEmpty || symbols == [variable]
    }

    private static func collectSymbols(_ expr: Expr) -> Set<Symbol> {
        var syms = Set<Symbol>()
        collectSymbols(expr, into: &syms)
        return syms
    }

    private static func collectSymbols(_ expr: Expr, into syms: inout Set<Symbol>) {
        switch expr {
        case .symbol(let s): syms.insert(s)
        case .integer, .rational, .decimal, .real, .constant: break
        case .add(let terms): terms.forEach { collectSymbols($0, into: &syms) }
        case .multiply(let factors): factors.forEach { collectSymbols($0, into: &syms) }
        case .power(let base, let exp):
            collectSymbols(base, into: &syms); collectSymbols(exp, into: &syms)
        case .negate(let inner): collectSymbols(inner, into: &syms)
        case .divide(let num, let den):
            collectSymbols(num, into: &syms); collectSymbols(den, into: &syms)
        case .function(_, let args): args.forEach { collectSymbols($0, into: &syms) }
        case .equation(let l, let r):
            collectSymbols(l, into: &syms); collectSymbols(r, into: &syms)
        case .relation(let l, _, let r):
            collectSymbols(l, into: &syms); collectSymbols(r, into: &syms)
        case .chainedRelation(let exprs, _):
            exprs.forEach { collectSymbols($0, into: &syms) }
        case .piecewise(let branches, let otherwise):
            branches.forEach { collectSymbols($0.value, into: &syms) }
            if let o = otherwise { collectSymbols(o, into: &syms) }
        case .tuple(let exprs), .vector(let exprs):
            exprs.forEach { collectSymbols($0, into: &syms) }
        case .matrix, .assignment, .functionDefinition, .unknown: break
        }
    }

    /// Extract coefficients a, b from a simplified expr representing `ax + b`.
    /// Returns (a: Expr, b: Expr) or nil if the expression is not linear.
    private static func extractLinearCoefficients(
        _ expr: Expr, variable: Symbol
    ) -> (a: Expr, b: Expr)? {
        let norm = ExpressionNormalizer().normalize(ExpressionSimplifier().simplify(expr))

        switch norm {
        case .add(let terms):
            var aTerms: [Expr] = []
            var bTerms: [Expr] = []
            for term in terms {
                if containsVariable(term, variable: variable) {
                    aTerms.append(term)
                } else {
                    bTerms.append(term)
                }
            }
            let a: Expr = aTerms.isEmpty ? .integer(0) : (aTerms.count == 1 ? aTerms[0] : .add(aTerms))
            let b: Expr = bTerms.isEmpty ? .integer(0) : (bTerms.count == 1 ? bTerms[0] : .add(bTerms))
            // Extract scalar coefficient from a
            guard let aScalar = extractScalarCoefficient(a, variable: variable) else { return nil }
            return (aScalar, b)
        case .symbol(let s) where s == variable:
            return (.integer(1), .integer(0))
        case .integer, .rational, .decimal, .real:
            return (.integer(0), norm)
        default:
            if containsVariable(norm, variable: variable) {
                guard let aScalar = extractScalarCoefficient(norm, variable: variable) else { return nil }
                return (aScalar, .integer(0))
            }
            return (.integer(0), norm)
        }
    }

    /// Extract the scalar coefficient of `variable` from a monomial.
    /// e.g. `2*x` → 2, `x` → 1, `-3*x` → -3.
    /// Returns nil if the term is not a simple scalar * variable.
    private static func extractScalarCoefficient(_ expr: Expr, variable: Symbol) -> Expr? {
        switch expr {
        case .symbol(let s) where s == variable:
            return .integer(1)
        case .multiply(let factors):
            let nonVar = factors.filter { !containsVariable($0, variable: variable) }
            // Every non-variable factor must be free of the variable
            let varFactors = factors.filter { containsVariable($0, variable: variable) }
            // Only allow: exactly one variable factor that is the symbol itself (x^1)
            guard varFactors.count == 1, case .symbol = varFactors[0] else { return nil }
            return nonVar.isEmpty ? .integer(1) : (nonVar.count == 1 ? nonVar[0] : .multiply(nonVar))
        case .negate(let inner):
            guard let coeff = extractScalarCoefficient(inner, variable: variable) else { return nil }
            return .negate(coeff)
        default:
            return nil
        }
    }

    private static func containsVariable(_ expr: Expr, variable: Symbol) -> Bool {
        switch expr {
        case .symbol(let s): return s == variable
        case .integer, .rational, .decimal, .real, .constant: return false
        case .add(let terms): return terms.contains(where: { containsVariable($0, variable: variable) })
        case .multiply(let factors): return factors.contains(where: { containsVariable($0, variable: variable) })
        case .power(let base, _): return containsVariable(base, variable: variable)
        case .negate(let inner): return containsVariable(inner, variable: variable)
        case .divide(let num, let den):
            return containsVariable(num, variable: variable) || containsVariable(den, variable: variable)
        case .function(_, let args):
            return args.contains(where: { containsVariable($0, variable: variable) })
        default: return false
        }
    }

    private static func isZero(_ expr: Expr) -> Bool {
        switch expr {
        case .integer(let v) where v == 0: return true
        case .real(let v) where v == 0: return true
        default: return false
        }
    }
}
