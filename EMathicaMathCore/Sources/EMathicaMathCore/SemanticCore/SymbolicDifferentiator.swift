import Foundation

/// Symbolic differentiation with respect to a given variable.
/// Returns the derivative Expr, or nil if the expression cannot be differentiated.
public enum SymbolicDifferentiator {

    public static func differentiate(_ expr: Expr, withRespectTo variable: Symbol) -> Expr? {
        switch expr {
        case .integer, .rational, .decimal, .real:
            return .integer(0)

        case .symbol(let sym):
            return sym == variable ? .integer(1) : .integer(0)

        case .constant:
            return .integer(0)

        case .add(let terms):
            let derived = terms.compactMap { differentiate($0, withRespectTo: variable) }
            guard derived.count == terms.count else { return nil }
            return .add(derived)

        case .multiply(let factors):
            return differentiateProduct(factors, withRespectTo: variable)

        case .power(let base, let exponent):
            return differentiatePower(base: base, exponent: exponent, variable: variable)

        case .negate(let inner):
            guard let d = differentiate(inner, withRespectTo: variable) else { return nil }
            return .negate(d)

        case .divide(let numerator, let denominator):
            guard let du = differentiate(numerator, withRespectTo: variable),
                  let dv = differentiate(denominator, withRespectTo: variable) else { return nil }
            // (u'v - uv') / v^2
            let term1: Expr = .multiply([du, denominator])
            let term2: Expr = .multiply([numerator, dv])
            let num: Expr = .add([term1, .negate(term2)])
            let den: Expr = .power(base: denominator, exponent: .integer(2))
            return .divide(numerator: num, denominator: den)

        case .function(let fn, let args):
            return differentiateFunction(fn, args: args, variable: variable)

        case .equation, .relation, .chainedRelation, .piecewise, .tuple, .vector, .matrix,
             .assignment, .functionDefinition, .unknown:
            return nil
        }
    }

    // MARK: - Product Rule

    private static func differentiateProduct(_ factors: [Expr], withRespectTo variable: Symbol) -> Expr? {
        guard !factors.isEmpty else { return .integer(0) }
        if factors.count == 1 {
            return differentiate(factors[0], withRespectTo: variable)
        }
        // d/dx (u*v) = u'*v + u*v'
        let u = factors[0]
        let v: Expr = factors.count == 2 ? factors[1] : .multiply(Array(factors.dropFirst()))
        guard let du = differentiate(u, withRespectTo: variable),
              let dv = differentiate(v, withRespectTo: variable) else { return nil }
        return .add([.multiply([du, v]), .multiply([u, dv])])
    }

    // MARK: - Power Rule

    private static func differentiatePower(base: Expr, exponent: Expr, variable: Symbol) -> Expr? {
        // Check if exponent is constant with respect to variable
        if !containsVariable(exponent, variable: variable) {
            // d/dx (u^n) = n * u^(n-1) * u'
            guard let du = differentiate(base, withRespectTo: variable) else { return nil }
            let n1: Expr = .add([exponent, .integer(-1)])
            let pow: Expr = .power(base: base, exponent: n1)
            return .multiply([exponent, pow, du])
        }
        // General case: rewrite u^v = exp(v * ln(u))
        // d/dx exp(v*ln(u)) = exp(v*ln(u)) * d/dx(v*ln(u))
        let rewritten: Expr = .function(.exp, arguments: [
            .multiply([exponent, .function(.ln, arguments: [base])])
        ])
        return differentiate(rewritten, withRespectTo: variable)
    }

    // MARK: - Function Derivatives

    private static func differentiateFunction(_ fn: MathFunction, args: [Expr], variable: Symbol) -> Expr? {
        guard let arg = args.first else { return nil }
        guard let du = differentiate(arg, withRespectTo: variable) else { return nil }

        switch fn {
        case .sin:
            // d/dx sin(u) = cos(u) * u'
            return .multiply([.function(.cos, arguments: [arg]), du])
        case .cos:
            // d/dx cos(u) = -sin(u) * u'
            return .multiply([.negate(.function(.sin, arguments: [arg])), du])
        case .tan:
            // d/dx tan(u) = sec(u)^2 * u' = (1/cos(u))^2 * u'
            let sec: Expr = .divide(numerator: .integer(1), denominator: .function(.cos, arguments: [arg]))
            return .multiply([.power(base: sec, exponent: .integer(2)), du])
        case .exp:
            // d/dx exp(u) = exp(u) * u'
            return .multiply([.function(.exp, arguments: [arg]), du])
        case .ln:
            // d/dx ln(u) = u' / u
            return .divide(numerator: du, denominator: arg)
        case .lg:
            // d/dx lg(u) = u' / (u * ln(10))
            let den: Expr = .multiply([arg, .function(.ln, arguments: [.integer(10)])])
            return .divide(numerator: du, denominator: den)
        case .log:
            return .divide(numerator: du, denominator: arg)
        case .sqrt:
            // d/dx sqrt(u) = u' / (2*sqrt(u))
            let den: Expr = .multiply([.integer(2), .function(.sqrt, arguments: [arg])])
            return .divide(numerator: du, denominator: den)
        case .asin:
            // d/dx asin(u) = u' / sqrt(1 - u^2)
            let inner: Expr = .add([.integer(1), .negate(.power(base: arg, exponent: .integer(2)))])
            return .divide(numerator: du, denominator: .function(.sqrt, arguments: [inner]))
        case .acos:
            let inner: Expr = .add([.integer(1), .negate(.power(base: arg, exponent: .integer(2)))])
            return .divide(numerator: .negate(du), denominator: .function(.sqrt, arguments: [inner]))
        case .atan:
            let den: Expr = .add([.integer(1), .power(base: arg, exponent: .integer(2))])
            return .divide(numerator: du, denominator: den)
        case .sinh:
            return .multiply([.function(.cosh, arguments: [arg]), du])
        case .cosh:
            return .multiply([.function(.sinh, arguments: [arg]), du])
        case .tanh:
            let sech: Expr = .divide(numerator: .integer(1), denominator: .function(.cosh, arguments: [arg]))
            return .multiply([.power(base: sech, exponent: .integer(2)), du])
        case .abs, .floor, .ceil, .min, .max, .custom:
            return nil
        case .logBase:
            // d/dx log_b(u) = u' / (u * ln(b))
            guard args.count >= 2 else { return nil }
            let b = args[1]
            let den: Expr = .multiply([arg, .function(.ln, arguments: [b])])
            return .divide(numerator: du, denominator: den)
        }
    }

    // MARK: - Helpers

    private static func containsVariable(_ expr: Expr, variable: Symbol) -> Bool {
        switch expr {
        case .symbol(let sym):
            return sym == variable
        case .integer, .rational, .decimal, .real, .constant:
            return false
        case .add(let terms):
            return terms.contains(where: { containsVariable($0, variable: variable) })
        case .multiply(let factors):
            return factors.contains(where: { containsVariable($0, variable: variable) })
        case .power(let base, let exponent):
            return containsVariable(base, variable: variable) || containsVariable(exponent, variable: variable)
        case .negate(let inner):
            return containsVariable(inner, variable: variable)
        case .divide(let num, let den):
            return containsVariable(num, variable: variable) || containsVariable(den, variable: variable)
        case .function(_, let args):
            return args.contains(where: { containsVariable($0, variable: variable) })
        case .equation(let left, let right):
            return containsVariable(left, variable: variable) || containsVariable(right, variable: variable)
        case .relation(let left, _, let right):
            return containsVariable(left, variable: variable) || containsVariable(right, variable: variable)
        case .chainedRelation(let exprs, _):
            return exprs.contains(where: { containsVariable($0, variable: variable) })
        case .piecewise(let branches, let otherwise):
            return branches.contains(where: { containsVariable($0.value, variable: variable) })
                || (otherwise.map { containsVariable($0, variable: variable) } ?? false)
        case .tuple(let exprs), .vector(let exprs):
            return exprs.contains(where: { containsVariable($0, variable: variable) })
        case .matrix:
            return false
        case .assignment(let target, let value):
            return containsVariable(target, variable: variable) || containsVariable(value, variable: variable)
        case .functionDefinition(_, let parameters, let body):
            return !parameters.contains(variable) && containsVariable(body, variable: variable)
        case .unknown:
            return false
        }
    }
}
