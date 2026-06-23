import Foundation

public enum AlgebraSimplifier {
    public struct Outcome {
        var expression: AlgebraExpression
        var diagnostics: [AlgebraDiagnostic]
    }

    public static func simplifyWithDiagnostics(_ expression: AlgebraExpression) -> Outcome {
        var diagnostics: [AlgebraDiagnostic] = []
        let expression = simplify(expression, diagnostics: &diagnostics)
        return Outcome(expression: expression, diagnostics: diagnostics)
    }

    public static func simplify(_ expression: AlgebraExpression) -> AlgebraExpression {
        var diagnostics: [AlgebraDiagnostic] = []
        return simplify(expression, diagnostics: &diagnostics)
    }

    private static func simplify(_ expression: AlgebraExpression, diagnostics: inout [AlgebraDiagnostic]) -> AlgebraExpression {
        switch expression {
        case .number, .symbol:
            return expression
        case .function(let name, let argument):
            return .function(name, simplify(argument, diagnostics: &diagnostics))
        case .power(let base, let exponent):
            let b = simplify(base, diagnostics: &diagnostics)
            let e = simplify(exponent, diagnostics: &diagnostics)
            if case .number(0) = e { return .number(1) }
            if case .number(1) = e { return b }
            if case .number(let lhs) = b, case .number(let rhs) = e {
                return .number(pow(lhs, rhs))
            }
            return .power(b, e)
        case .divide(let numerator, let denominator):
            let n = simplify(numerator, diagnostics: &diagnostics)
            let d = simplify(denominator, diagnostics: &diagnostics)
            if case .number(0) = n { return .number(0) }
            if case .number(1) = d { return n }
            if case .number(let lhs) = n, case .number(let rhs) = d, rhs != 0 {
                return .number(lhs / rhs)
            }
            if n == d {
                appendRemovableDiscontinuities(from: d, diagnostics: &diagnostics)
                return .number(1)
            }
            if let canceled = cancelPolynomialFraction(numerator: n, denominator: d, diagnostics: &diagnostics) {
                return simplify(canceled, diagnostics: &diagnostics)
            }
            if let canceled = cancelCommonFactors(numerator: n, denominator: d, diagnostics: &diagnostics) {
                return simplify(canceled, diagnostics: &diagnostics)
            }
            return .divide(n, d)
        case .add(let terms):
            let simplified = terms.flatMap { term -> [AlgebraExpression] in
                let item = simplify(term, diagnostics: &diagnostics)
                if case .add(let nested) = item { return nested }
                return [item]
            }
            var constant = 0.0
            var rest: [AlgebraExpression] = []
            for term in simplified {
                if case .number(let value) = term {
                    constant += value
                } else {
                    rest.append(term)
                }
            }
            if constant != 0 { rest.append(.number(constant)) }
            if rest.isEmpty { return .number(0) }
            if let combined = combineLikeTerms(rest, constant: constant) {
                return combined
            }
            if rest.count == 1 { return rest[0] }
            let added = AlgebraExpression.add(rest.sorted { AlgebraLatexFormatter.format($0) < AlgebraLatexFormatter.format($1) })
            return factorSimpleQuadratic(added) ?? added
        case .multiply(let factors):
            let simplified = factors.flatMap { factor -> [AlgebraExpression] in
                let item = simplify(factor, diagnostics: &diagnostics)
                if case .multiply(let nested) = item { return nested }
                return [item]
            }
            var constant = 1.0
            var rest: [AlgebraExpression] = []
            for factor in simplified {
                if case .number(let value) = factor {
                    constant *= value
                } else {
                    rest.append(factor)
                }
            }
            if constant == 0 { return .number(0) }
            if constant != 1 { rest.insert(.number(constant), at: 0) }
            if rest.isEmpty { return .number(1) }
            if rest.count == 1 { return rest[0] }
            return expandPolynomialProductIfPossible(.multiply(rest)) ?? .multiply(rest)
        }
    }

    private static func combineLikeTerms(_ terms: [AlgebraExpression], constant: Double) -> AlgebraExpression? {
        let expression = AlgebraExpression.add(terms)
        guard let polynomial = SingleVariablePolynomial.make(from: expression), polynomial.degree <= 4 else { return nil }
        let combined = polynomial.expression
        if constant == 0, combined == expression {
            return nil
        }
        return factorSimpleQuadratic(combined) ?? combined
    }

    private static func expandPolynomialProductIfPossible(_ expression: AlgebraExpression) -> AlgebraExpression? {
        guard let polynomial = SingleVariablePolynomial.make(from: expression), polynomial.degree <= 4 else { return nil }
        let expanded = polynomial.expression
        return expanded == expression ? nil : expanded
    }

    private static func cancelCommonFactors(
        numerator: AlgebraExpression,
        denominator: AlgebraExpression,
        diagnostics: inout [AlgebraDiagnostic]
    ) -> AlgebraExpression? {
        let numeratorFactors = factors(in: numerator)
        let denominatorFactors = factors(in: denominator)

        for (nIndex, nFactor) in numeratorFactors.enumerated() {
            if let dIndex = denominatorFactors.firstIndex(of: nFactor) {
                appendRemovableDiscontinuities(from: nFactor, diagnostics: &diagnostics)
                var nextNumerator = numeratorFactors
                var nextDenominator = denominatorFactors
                nextNumerator.remove(at: nIndex)
                nextDenominator.remove(at: dIndex)
                return .divide(product(nextNumerator), product(nextDenominator))
            }
        }
        return nil
    }

    private static func cancelPolynomialFraction(
        numerator: AlgebraExpression,
        denominator: AlgebraExpression,
        diagnostics: inout [AlgebraDiagnostic]
    ) -> AlgebraExpression? {
        guard
            let n = SingleVariablePolynomial.make(from: numerator),
            let d = SingleVariablePolynomial.make(from: denominator),
            n.variable == d.variable,
            d.degree >= 1,
            let division = n.divided(by: d),
            division.remainder.isZero
        else {
            return nil
        }

        appendRemovableDiscontinuities(from: denominator, diagnostics: &diagnostics)
        return division.quotient.expression
    }

    private static func factorSimpleQuadratic(_ expression: AlgebraExpression) -> AlgebraExpression? {
        guard
            let polynomial = SingleVariablePolynomial.make(from: expression),
            polynomial.degree == 2,
            let factors = polynomial.integerRootFactors()
        else {
            return nil
        }
        return .multiply(factors)
    }

    private static func appendRemovableDiscontinuities(
        from denominator: AlgebraExpression,
        diagnostics: inout [AlgebraDiagnostic]
    ) {
        guard let roots = SingleVariablePolynomial.make(from: denominator)?.realLinearRoots(), !roots.isEmpty else { return }
        let values = roots.map { "\($0.variable) = \(formatNumber($0.value))" }.joined(separator: ", ")
        diagnostics.append(AlgebraDiagnostic(severity: .info, message: "约分产生可去间断点：\(values)"))
    }

    private static func factors(in expression: AlgebraExpression) -> [AlgebraExpression] {
        if case .multiply(let factors) = expression {
            return factors
        }
        return [expression]
    }

    private static func product(_ factors: [AlgebraExpression]) -> AlgebraExpression {
        if factors.isEmpty { return .number(1) }
        if factors.count == 1 { return factors[0] }
        return .multiply(factors)
    }

    private static func formatNumber(_ value: Double) -> String {
        let rounded = (value * 1_000_000).rounded() / 1_000_000
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}

private struct SingleVariablePolynomial: Equatable {
    public var variable: String
    public var coefficients: [Int: Double]

    public var degree: Int {
        coefficients.keys.max() ?? 0
    }

    public var isZero: Bool {
        coefficients.values.allSatisfy { abs($0) < 0.000001 }
    }

    public var expression: AlgebraExpression {
        let terms = coefficients
            .filter { abs($0.value) > 0.000001 }
            .sorted { $0.key > $1.key }
            .map { power, coefficient -> AlgebraExpression in
                let base: AlgebraExpression
                switch power {
                case 0:
                    return .number(coefficient)
                case 1:
                    base = .symbol(variable)
                default:
                    base = .power(.symbol(variable), .number(Double(power)))
                }
                if abs(coefficient - 1) < 0.000001 {
                    return base
                }
                if abs(coefficient + 1) < 0.000001 {
                    return .multiply([.number(-1), base])
                }
                return .multiply([.number(coefficient), base])
            }
        if terms.isEmpty { return .number(0) }
        if terms.count == 1 { return terms[0] }
        return .add(terms)
    }

    public static func make(from expression: AlgebraExpression) -> SingleVariablePolynomial? {
        switch expression {
        case .number(let value):
            return SingleVariablePolynomial(variable: "x", coefficients: [0: value]).cleaned()
        case .symbol(let name) where !["pi", "e"].contains(name):
            return SingleVariablePolynomial(variable: name, coefficients: [1: 1])
        case .power(.symbol(let name), .number(let exponent)) where !["pi", "e"].contains(name):
            let rounded = exponent.rounded()
            guard abs(exponent - rounded) < 0.000001, rounded >= 0 else { return nil }
            return SingleVariablePolynomial(variable: name, coefficients: [Int(rounded): 1])
        case .add(let terms):
            var result: SingleVariablePolynomial?
            for term in terms {
                guard let polynomial = make(from: term) else { return nil }
                if let current = result {
                    guard let added = current.adding(polynomial) else { return nil }
                    result = added
                } else {
                    result = polynomial
                }
            }
            return result?.cleaned()
        case .multiply(let factors):
            var result: SingleVariablePolynomial?
            for factor in factors {
                guard let polynomial = make(from: factor) else { return nil }
                if let current = result {
                    guard let multiplied = current.multiplied(by: polynomial) else { return nil }
                    result = multiplied
                } else {
                    result = polynomial
                }
            }
            return result?.cleaned()
        default:
            return nil
        }
    }

    public func divided(by divisor: SingleVariablePolynomial) -> (quotient: SingleVariablePolynomial, remainder: SingleVariablePolynomial)? {
        guard variable == divisor.variable, !divisor.isZero else { return nil }
        var remainder = cleaned()
        var quotient = SingleVariablePolynomial(variable: variable, coefficients: [:])
        let divisorDegree = divisor.degree
        let divisorLead = divisor.coefficient(divisorDegree)

        while !remainder.isZero, remainder.degree >= divisorDegree {
            let power = remainder.degree - divisorDegree
            let coefficient = remainder.coefficient(remainder.degree) / divisorLead
            let term = SingleVariablePolynomial(variable: variable, coefficients: [power: coefficient])
            guard
                let nextQuotient = quotient.adding(term),
                let product = divisor.multiplied(by: term),
                let nextRemainder = remainder.adding(product.scaled(by: -1))
            else {
                return nil
            }
            quotient = nextQuotient
            remainder = nextRemainder.cleaned()
        }

        return (quotient.cleaned(), remainder.cleaned())
    }

    public func integerRootFactors() -> [AlgebraExpression]? {
        let a = coefficient(2)
        let b = coefficient(1)
        let c = coefficient(0)
        guard abs(a.rounded() - a) < 0.000001, abs(b.rounded() - b) < 0.000001, abs(c.rounded() - c) < 0.000001 else { return nil }

        let discriminant = b * b - 4 * a * c
        guard discriminant >= 0 else { return nil }
        let sqrtD = sqrt(discriminant)
        guard abs(sqrtD.rounded() - sqrtD) < 0.000001 else { return nil }

        let denominator = 2 * a
        let r1 = (-b + sqrtD) / denominator
        let r2 = (-b - sqrtD) / denominator
        guard abs(r1.rounded() - r1) < 0.000001, abs(r2.rounded() - r2) < 0.000001 else { return nil }

        let leading = abs(a - 1) < 0.000001 ? [] : [AlgebraExpression.number(a)]
        return leading + [linearFactor(root: r1), linearFactor(root: r2)]
    }

    public func realLinearRoots() -> [(variable: String, value: Double)] {
        if degree == 1 {
            let a = coefficient(1)
            guard abs(a) > 0.000001 else { return [] }
            return [(variable, -coefficient(0) / a)]
        }
        if degree == 2 {
            let a = coefficient(2)
            let b = coefficient(1)
            let c = coefficient(0)
            let discriminant = b * b - 4 * a * c
            guard discriminant >= 0, abs(a) > 0.000001 else { return [] }
            let sqrtD = sqrt(discriminant)
            return [(variable, (-b + sqrtD) / (2 * a)), (variable, (-b - sqrtD) / (2 * a))]
        }
        return []
    }

    private func linearFactor(root: Double) -> AlgebraExpression {
        if abs(root) < 0.000001 {
            return .symbol(variable)
        }
        return .add([.symbol(variable), .number(-root)])
    }

    private func adding(_ other: SingleVariablePolynomial) -> SingleVariablePolynomial? {
        guard variable == other.variable || isConstant || other.isConstant else { return nil }
        let nextVariable = isConstant ? other.variable : variable
        var next = coefficients
        for (power, coefficient) in other.coefficients {
            next[power, default: 0] += coefficient
        }
        return SingleVariablePolynomial(variable: nextVariable, coefficients: next).cleaned()
    }

    private func multiplied(by other: SingleVariablePolynomial) -> SingleVariablePolynomial? {
        guard variable == other.variable || isConstant || other.isConstant else { return nil }
        let nextVariable = isConstant ? other.variable : variable
        var next: [Int: Double] = [:]
        for (lhsPower, lhsCoefficient) in coefficients {
            for (rhsPower, rhsCoefficient) in other.coefficients {
                next[lhsPower + rhsPower, default: 0] += lhsCoefficient * rhsCoefficient
            }
        }
        return SingleVariablePolynomial(variable: nextVariable, coefficients: next).cleaned()
    }

    private func scaled(by value: Double) -> SingleVariablePolynomial {
        SingleVariablePolynomial(
            variable: variable,
            coefficients: coefficients.mapValues { $0 * value }
        ).cleaned()
    }

    private var isConstant: Bool {
        coefficients.keys.allSatisfy { $0 == 0 }
    }

    private func coefficient(_ power: Int) -> Double {
        coefficients[power] ?? 0
    }

    private func cleaned() -> SingleVariablePolynomial {
        SingleVariablePolynomial(
            variable: variable,
            coefficients: coefficients.filter { abs($0.value) > 0.000001 }
        )
    }
}
