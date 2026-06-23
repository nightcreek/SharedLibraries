public struct ExprDebugPrinter {
    public init() {}

    public func print(_ expr: Expr) -> String {
        switch expr {
        case .integer(let value):
            return "integer(\(value))"
        case .rational(let n, let d):
            return "rational(\(n), \(d))"
        case .decimal(let value):
            return "decimal(\(value))"
        case .real(let value):
            return "real(\(value))"
        case .symbol(let symbol):
            return "symbol(\(symbol.name))"
        case .constant(let constant):
            return "constant(\(constant.rawValue))"
        case .add(let terms):
            return "add([\((terms.map(print).joined(separator: ", ")))])"
        case .multiply(let factors):
            return "multiply([\((factors.map(print).joined(separator: ", ")))])"
        case .power(let base, let exponent):
            return "power(\(print(base)), \(print(exponent)))"
        case .negate(let value):
            return "negate(\(print(value)))"
        case .divide(let numerator, let denominator):
            return "divide(\(print(numerator)), \(print(denominator)))"
        case .function(let function, let arguments):
            return "function(\(functionName(function)), [\((arguments.map(print).joined(separator: ", ")))])"
        case .equation(let left, let right):
            return "equation(\(print(left)), \(print(right)))"
        case .relation(let left, let relation, let right):
            return "relation(\(print(left)), \(relation.rawValue), \(print(right)))"
        case .chainedRelation(let expressions, let relations):
            let exprs = expressions.map(print).joined(separator: ", ")
            let rels = relations.map(\.rawValue).joined(separator: ", ")
            return "chainedRelation(exprs:[\(exprs)], rels:[\(rels)])"
        case .piecewise(let branches, let otherwise):
            let renderedBranches = branches.map {
                "{value:\(print($0.value)), cond:\(print($0.condition))}"
            }.joined(separator: ", ")
            let renderedOtherwise = otherwise.map(print) ?? "nil"
            return "piecewise([\(renderedBranches)], otherwise:\(renderedOtherwise))"
        case .tuple(let values):
            return "tuple([\((values.map(print).joined(separator: ", ")))])"
        case .vector(let values):
            return "vector([\((values.map(print).joined(separator: ", ")))])"
        case .matrix(let matrix):
            let rows = matrix.rows.map { row in
                "[\(row.map(print).joined(separator: ", "))]"
            }.joined(separator: ", ")
            return "matrix([\((rows))])"
        case .assignment(let target, let value):
            return "assignment(\(print(target)), \(print(value)))"
        case .functionDefinition(let name, let parameters, let body):
            let params = parameters.map(\.name).joined(separator: ", ")
            return "functionDefinition(\(name.name), [\(params)], \(print(body)))"
        case .unknown(let value):
            return "unknown(\(value))"
        }
    }

    private func functionName(_ function: MathFunction) -> String {
        switch function {
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
        case .log: return "log"
        case .logBase: return "logBase"
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
