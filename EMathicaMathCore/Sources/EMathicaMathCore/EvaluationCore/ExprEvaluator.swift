import Foundation

public struct EvaluationOptions: Sendable {
    public var epsilon: Double

    public init(epsilon: Double = 1e-12) {
        self.epsilon = epsilon
    }
}

public struct ExprEvaluator {
    public var options: EvaluationOptions

    public init(options: EvaluationOptions = .init()) {
        self.options = options
    }

    public func evaluate(
        _ expr: Expr,
        environment: EvaluationEnvironment = .init()
    ) -> EvaluationResult {
        switch expr {
        case .integer(let value):
            return .value(Double(value))
        case .rational(let numerator, let denominator):
            if isApproximatelyZero(Double(denominator)) {
                return .undefined(issue(.divisionByZero, "rational denominator is zero"))
            }
            return finiteResult(Double(numerator) / Double(denominator))
        case .decimal(let raw):
            guard let value = Double(raw) else {
                return .undefined(issue(.unsupportedExpression, "invalid decimal literal: \(raw)"))
            }
            return finiteResult(value)
        case .real(let value):
            return finiteResult(value)
        case .constant(let constant):
            switch constant {
            case .pi:
                return .value(Double.pi)
            case .e:
                return .value(M_E)
            case .imaginaryUnit, .infinity:
                return .undefined(issue(.unsupportedExpression, "constant \(constant.rawValue) is not real-evaluable in this evaluator"))
            }
        case .symbol(let symbol):
            guard let value = environment.value(for: symbol) else {
                return .undefined(issue(.missingVariable, "missing value for symbol: \(symbol.name)"))
            }
            return finiteResult(value)

        case .add(let terms):
            var sum = 0.0
            for term in terms {
                switch evaluate(term, environment: environment) {
                case .value(let value):
                    sum += value
                case .undefined(let issue):
                    return .undefined(issue)
                }
            }
            return finiteResult(sum)

        case .multiply(let factors):
            var product = 1.0
            for factor in factors {
                switch evaluate(factor, environment: environment) {
                case .value(let value):
                    product *= value
                case .undefined(let issue):
                    return .undefined(issue)
                }
            }
            return finiteResult(product)

        case .negate(let value):
            switch evaluate(value, environment: environment) {
            case .value(let v):
                return finiteResult(-v)
            case .undefined(let issue):
                return .undefined(issue)
            }

        case .divide(let numerator, let denominator):
            let numeratorResult = evaluate(numerator, environment: environment)
            let denominatorResult = evaluate(denominator, environment: environment)
            switch (numeratorResult, denominatorResult) {
            case (.undefined(let issue), _), (_, .undefined(let issue)):
                return .undefined(issue)
            case (.value(let n), .value(let d)):
                if isApproximatelyZero(d) {
                    return .undefined(issue(.divisionByZero, "division denominator is zero"))
                }
                return finiteResult(n / d)
            }

        case .power(let base, let exponent):
            let baseResult = evaluate(base, environment: environment)
            let exponentResult = evaluate(exponent, environment: environment)
            switch (baseResult, exponentResult) {
            case (.undefined(let issue), _), (_, .undefined(let issue)):
                return .undefined(issue)
            case (.value(let b), .value(let e)):
                if b < 0, !isIntegerValue(e) {
                    return .undefined(issue(.invalidPower, "fractional exponent on negative base"))
                }
                return finiteResult(pow(b, e), nonFiniteKind: .invalidPower)
            }

        case .function(let function, let arguments):
            return evaluateFunction(function, arguments: arguments, environment: environment)

        case .piecewise(let branches, let otherwise):
            let conditionEvaluator = ConditionEvaluator(evaluator: self)
            for branch in branches {
                switch conditionEvaluator.evaluate(branch.condition, environment: environment) {
                case .satisfied:
                    return evaluate(branch.value, environment: environment)
                case .unsatisfied:
                    continue
                case .undefined(let issue):
                    return .undefined(issue)
                }
            }
            if let otherwise {
                return evaluate(otherwise, environment: environment)
            }
            return .undefined(issue(.unsupportedExpression, "piecewise has no matching branch for environment"))

        case .equation, .relation, .chainedRelation,
             .tuple, .vector, .matrix,
             .assignment, .functionDefinition, .unknown:
            return .undefined(issue(.unsupportedExpression, "expression is not directly evaluable"))
        }
    }

    private func evaluateFunction(
        _ function: MathFunction,
        arguments: [Expr],
        environment: EvaluationEnvironment
    ) -> EvaluationResult {
        func evalArg(_ index: Int) -> EvaluationResult {
            guard index < arguments.count else {
                return .undefined(issue(.unsupportedExpression, "missing function argument"))
            }
            return evaluate(arguments[index], environment: environment)
        }

        switch function {
        case .sin:
            return unary(arguments, env: environment) { finiteResult(sin($0)) }
        case .cos:
            return unary(arguments, env: environment) { finiteResult(cos($0)) }
        case .tan:
            return unary(arguments, env: environment) { value in
                if isApproximatelyZero(cos(value)) {
                    return .undefined(issue(.tangentUndefined, "tan undefined near odd pi/2"))
                }
                return finiteResult(tan(value))
            }
        case .exp:
            return unary(arguments, env: environment) { finiteResult(exp($0)) }
        case .ln:
            return unary(arguments, env: environment) { value in
                guard value > 0 else {
                    return .undefined(issue(.logarithmOfNonPositive, "ln input must be > 0"))
                }
                return finiteResult(log(value))
            }
        case .lg:
            return unary(arguments, env: environment) { value in
                guard value > 0 else {
                    return .undefined(issue(.logarithmOfNonPositive, "lg input must be > 0"))
                }
                return finiteResult(log10(value))
            }
        case .log:
            if arguments.count == 1 {
                return .undefined(issue(.ambiguousLogBase, "log(x) base is ambiguous; use ln/lg/logBase"))
            }
            if arguments.count == 2 {
                return evaluateFunction(.logBase, arguments: arguments, environment: environment)
            }
            return .undefined(issue(.unsupportedExpression, "log expects 1 or 2 arguments"))
        case .logBase:
            guard arguments.count == 2 else {
                return .undefined(issue(.unsupportedExpression, "logBase expects 2 arguments"))
            }
            let baseResult = evalArg(0)
            let xResult = evalArg(1)
            switch (baseResult, xResult) {
            case (.undefined(let issue), _), (_, .undefined(let issue)):
                return .undefined(issue)
            case (.value(let base), .value(let x)):
                guard x > 0 else {
                    return .undefined(issue(.logarithmOfNonPositive, "logBase input must be > 0"))
                }
                guard base > 0, abs(base - 1) > options.epsilon else {
                    return .undefined(issue(.invalidLogBase, "logBase base must be > 0 and != 1"))
                }
                return finiteResult(log(x) / log(base))
            }
        case .sqrt:
            return unary(arguments, env: environment) { value in
                guard value >= 0 else {
                    return .undefined(issue(.squareRootOfNegative, "sqrt input must be >= 0"))
                }
                return finiteResult(sqrt(value))
            }
        case .abs:
            return unary(arguments, env: environment) { finiteResult(abs($0)) }
        case .floor:
            return unary(arguments, env: environment) { finiteResult(Foundation.floor($0)) }
        case .ceil:
            return unary(arguments, env: environment) { finiteResult(Foundation.ceil($0)) }
        case .min:
            return variadic(arguments, env: environment, emptyKind: .unsupportedExpression) { values in
                guard let first = values.first else {
                    return .undefined(issue(.unsupportedExpression, "min requires at least one argument"))
                }
                return finiteResult(values.dropFirst().reduce(first, Swift.min))
            }
        case .max:
            return variadic(arguments, env: environment, emptyKind: .unsupportedExpression) { values in
                guard let first = values.first else {
                    return .undefined(issue(.unsupportedExpression, "max requires at least one argument"))
                }
                return finiteResult(values.dropFirst().reduce(first, Swift.max))
            }
        case .sinh:
            return unary(arguments, env: environment) { finiteResult(Foundation.sinh($0)) }
        case .cosh:
            return unary(arguments, env: environment) { finiteResult(Foundation.cosh($0)) }
        case .tanh:
            return unary(arguments, env: environment) { finiteResult(Foundation.tanh($0)) }
        case .asin, .acos, .atan, .custom:
            return .undefined(issue(.unsupportedExpression, "function not supported by first evaluator pass"))
        }
    }

    private func unary(
        _ args: [Expr],
        env: EvaluationEnvironment,
        op: (Double) -> EvaluationResult
    ) -> EvaluationResult {
        guard args.count == 1 else {
            return .undefined(issue(.unsupportedExpression, "function expects exactly 1 argument"))
        }
        switch evaluate(args[0], environment: env) {
        case .value(let value):
            return op(value)
        case .undefined(let issue):
            return .undefined(issue)
        }
    }

    private func variadic(
        _ args: [Expr],
        env: EvaluationEnvironment,
        emptyKind: EvaluationIssueKind,
        op: ([Double]) -> EvaluationResult
    ) -> EvaluationResult {
        if args.isEmpty {
            return .undefined(issue(emptyKind, "function expects at least one argument"))
        }
        var values: [Double] = []
        values.reserveCapacity(args.count)
        for arg in args {
            switch evaluate(arg, environment: env) {
            case .value(let value):
                values.append(value)
            case .undefined(let issue):
                return .undefined(issue)
            }
        }
        return op(values)
    }

    private func finiteResult(_ value: Double, nonFiniteKind: EvaluationIssueKind = .nonFiniteResult) -> EvaluationResult {
        if value.isFinite {
            return .value(value)
        }
        return .undefined(issue(nonFiniteKind, "result is not finite"))
    }

    private func isApproximatelyZero(_ value: Double) -> Bool {
        abs(value) <= options.epsilon
    }

    private func isIntegerValue(_ value: Double) -> Bool {
        abs(value.rounded() - value) <= options.epsilon
    }

    private func issue(_ kind: EvaluationIssueKind, _ message: String) -> EvaluationIssue {
        EvaluationIssue(kind: kind, message: message)
    }
}
