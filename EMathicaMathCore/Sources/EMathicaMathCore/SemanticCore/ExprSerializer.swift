import Foundation

/// Produces a stable, parseable source string from an `Expr`.
/// Unlike `ExprDebugPrinter` (which is a debug tool), this serializer
/// guarantees output that can be re-parsed by the LaTeX/expression parser.
public enum ExprSerializer {

    /// Serialize `expr` to a source string suitable for re-parsing.
    /// Returns nil if the expression contains constructs that cannot be
    /// reliably serialized (e.g. piecewise, vectors, matrices).
    public static func serialize(_ expr: Expr) -> String? {
        var result = ""
        guard serialize(expr, into: &result, parentPrecedence: 0) else { return nil }
        return result
    }

    // MARK: - Precedence

    private static func precedence(of expr: Expr) -> Int {
        switch expr {
        case .add:       return 1
        case .negate:    return 2
        case .multiply:  return 3
        case .divide:    return 3
        case .power:     return 4
        case .function:  return 5
        default:         return 5
        }
    }

    // MARK: - Recursive serialization

    private static func serialize(_ expr: Expr, into result: inout String, parentPrecedence: Int) -> Bool {
        switch expr {
        case .integer(let value):
            result.append(String(value))
            return true
        case .real(let value):
            result.append(formatReal(value))
            return true
        case .rational(let n, let d):
            result.append("\(n)/\(d)")
            return true
        case .decimal(let text):
            result.append(text)
            return true
        case .symbol(let sym):
            result.append(sym.name)
            return true
        case .constant(let c):
            switch c {
            case .pi: result.append("pi"); return true
            case .e: result.append("e"); return true
            case .infinity: result.append("infinity"); return true
            case .imaginaryUnit: result.append("i"); return true
            }
        case .negate(let inner):
            result.append("-")
            let innerPrec = precedence(of: inner)
            let needParens = innerPrec < 2
            if needParens { result.append("(") }
            guard serialize(inner, into: &result, parentPrecedence: 2) else { return false }
            if needParens { result.append(")") }
            return true
        case .add(let terms):
            guard !terms.isEmpty else { result.append("0"); return true }
            let needParens = parentPrecedence > 1
            if needParens { result.append("(") }
            for (i, term) in terms.enumerated() {
                if i > 0 {
                    // Check if this term is a negate of a positive value — use "-" instead of "+ -"
                    if case .negate(let inner) = term, !isNegativeConstant(inner) {
                        result.append(" - ")
                        guard serialize(inner, into: &result, parentPrecedence: 1) else { return false }
                    } else {
                        result.append(" + ")
                        guard serialize(term, into: &result, parentPrecedence: 1) else { return false }
                    }
                } else {
                    guard serialize(term, into: &result, parentPrecedence: 1) else { return false }
                }
            }
            if needParens { result.append(")") }
            return true
        case .multiply(let factors):
            guard !factors.isEmpty else { result.append("1"); return true }
            let needParens = parentPrecedence > 3
            if needParens { result.append("(") }
            for (i, factor) in factors.enumerated() {
                if i > 0 {
                    // Omit * between a number and an identifier: 2*x → 2x
                    let prev = factors[i - 1]
                    if !isNumericConstant(prev) || !startsWithIdentifier(factor) {
                        result.append("*")
                    }
                }
                let fp = precedence(of: factor)
                let wrap = fp < 3
                if wrap { result.append("(") }
                guard serialize(factor, into: &result, parentPrecedence: 3) else { return false }
                if wrap { result.append(")") }
            }
            if needParens { result.append(")") }
            return true
        case .divide(let num, let den):
            let np = precedence(of: num)
            if np < 3 { result.append("(") }
            guard serialize(num, into: &result, parentPrecedence: 3) else { return false }
            if np < 3 { result.append(")") }
            result.append("/")
            let dp = precedence(of: den)
            if dp <= 3 { result.append("(") }
            guard serialize(den, into: &result, parentPrecedence: 3) else { return false }
            if dp <= 3 { result.append(")") }
            return true
        case .power(let base, let exponent):
            let bp = precedence(of: base)
            if bp < 4 { result.append("(") }
            guard serialize(base, into: &result, parentPrecedence: 4) else { return false }
            if bp < 4 { result.append(")") }
            result.append("^")
            let ep = precedence(of: exponent)
            if ep <= 4 { result.append("(") }
            guard serialize(exponent, into: &result, parentPrecedence: 4) else { return false }
            if ep <= 4 { result.append(")") }
            return true
        case .function(let fn, let args):
            switch fn {
            case .sin, .cos, .tan, .asin, .acos, .atan, .sinh, .cosh, .tanh,
                 .exp, .ln, .lg, .abs, .floor, .ceil:
                result.append(fn.nameForSerialization)
                result.append("(")
                guard let first = args.first else { result.append(")"); return true }
                guard serialize(first, into: &result, parentPrecedence: 0) else { return false }
                result.append(")")
                return true
            case .sqrt:
                result.append("sqrt(")
                guard let first = args.first else { result.append(")"); return true }
                guard serialize(first, into: &result, parentPrecedence: 0) else { return false }
                result.append(")")
                return true
            case .log:
                result.append("ln(")
                guard let first = args.first else { result.append(")"); return true }
                guard serialize(first, into: &result, parentPrecedence: 0) else { return false }
                result.append(")")
                return true
            case .logBase:
                guard args.count >= 2 else { return false }
                result.append("log(")
                guard serialize(args[0], into: &result, parentPrecedence: 0) else { return false }
                result.append(",")
                guard serialize(args[1], into: &result, parentPrecedence: 0) else { return false }
                result.append(")")
                return true
            case .min, .max:
                guard !args.isEmpty else { return false }
                result.append(fn.nameForSerialization)
                result.append("(")
                for (i, arg) in args.enumerated() {
                    if i > 0 { result.append(",") }
                    guard serialize(arg, into: &result, parentPrecedence: 0) else { return false }
                }
                result.append(")")
                return true
            case .custom(let name):
                result.append(name)
                result.append("(")
                for (i, arg) in args.enumerated() {
                    if i > 0 { result.append(",") }
                    guard serialize(arg, into: &result, parentPrecedence: 0) else { return false }
                }
                result.append(")")
                return true
            case .log:
                result.append("ln(")
                guard let first = args.first else { result.append(")"); return true }
                guard serialize(first, into: &result, parentPrecedence: 0) else { return false }
                result.append(")")
                return true
            }
        case .equation, .relation, .chainedRelation, .piecewise,
             .tuple, .vector, .matrix, .assignment, .functionDefinition,
             .unknown:
            return false
        }
    }

    private static func isNegativeConstant(_ expr: Expr) -> Bool {
        switch expr {
        case .integer(let v) where v < 0: return true
        case .real(let v) where v < 0: return true
        default: return false
        }
    }

    private static func formatReal(_ value: Double) -> String {
        if value == Double(Int(value)) {
            return String(Int(value))
        }
        return String(value)
    }

    private static func isNumericConstant(_ expr: Expr) -> Bool {
        switch expr {
        case .integer, .rational, .decimal, .real: return true
        case .negate(let inner): return isNumericConstant(inner)
        default: return false
        }
    }

    private static func startsWithIdentifier(_ expr: Expr) -> Bool {
        switch expr {
        case .symbol, .constant: return true
        case .function: return true
        default: return false
        }
    }
}

// MARK: - Serialization names

extension MathFunction {
    fileprivate var nameForSerialization: String {
        switch self {
        case .sin: return "sin"
        case .cos: return "cos"
        case .tan: return "tan"
        case .asin: return "asin"
        case .acos: return "acos"
        case .atan: return "atan"
        case .sinh: return "sinh"
        case .cosh: return "cosh"
        case .tanh: return "tanh"
        case .exp: return "exp"
        case .ln: return "ln"
        case .lg: return "lg"
        case .log: return "ln"
        case .logBase: return "log"
        case .sqrt: return "sqrt"
        case .abs: return "abs"
        case .floor: return "floor"
        case .ceil: return "ceil"
        case .min: return "min"
        case .max: return "max"
        case .custom(let name): return name
        }
    }
}
