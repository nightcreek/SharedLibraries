import Foundation

public enum AlgebraEvaluator {
    public static func evaluate(_ expression: AlgebraExpression, variables: [String: Double]) -> Double? {
        switch expression {
        case .number(let value):
            return value
        case .symbol("pi"):
            return Double.pi
        case .symbol("e"):
            return M_E
        case .symbol(let name):
            return variables[name]
        case .add(let terms):
            return terms.reduce(Optional(0.0)) { partial, term in
                guard let partial, let value = evaluate(term, variables: variables) else { return nil }
                return partial + value
            }
        case .multiply(let factors):
            return factors.reduce(Optional(1.0)) { partial, factor in
                guard let partial, let value = evaluate(factor, variables: variables) else { return nil }
                return partial * value
            }
        case .divide(let numerator, let denominator):
            guard let n = evaluate(numerator, variables: variables), let d = evaluate(denominator, variables: variables), d != 0 else { return nil }
            return n / d
        case .power(let base, let exponent):
            guard let b = evaluate(base, variables: variables), let e = evaluate(exponent, variables: variables) else { return nil }
            return pow(b, e)
        case .function(let name, let argument):
            guard let value = evaluate(argument, variables: variables) else { return nil }
            switch name {
            case "sin": return sin(value)
            case "cos": return cos(value)
            case "tan": return tan(value)
            case "sqrt": return value >= 0 ? sqrt(value) : nil
            case "abs": return abs(value)
            case "log", "ln": return value > 0 ? log(value) : nil
            case "exp": return exp(value)
            default: return nil
            }
        }
    }
}
