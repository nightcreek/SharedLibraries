import Foundation

public enum SuperellipseRecognizer {
    public static func recognize(_ relation: AlgebraRelation) -> ParametricRewriteInfo? {
        guard case .equation(let equation) = relation else { return nil }

        let leftTerms = additiveTerms(equation.left)
        guard leftTerms.count == 2, case .number(let rightConstant) = equation.right, rightConstant > 0 else {
            return nil
        }

        guard
            let first = parseTerm(leftTerms[0]),
            let second = parseTerm(leftTerms[1]),
            first.variable != second.variable,
            first.exponentSymbol == second.exponentSymbol,
            first.numericExponentMatches(second),
            first.resolvedExponentForValidation > 0,
            first.coefficient > 0,
            second.coefficient > 0
        else {
            return nil
        }

        let xTerm: AxisTerm
        let yTerm: AxisTerm
        if first.variable == "x", second.variable == "y" {
            xTerm = first
            yTerm = second
        } else if first.variable == "y", second.variable == "x" {
            xTerm = second
            yTerm = first
        } else {
            return nil
        }

        let n = xTerm.exponent
        let radiusX = xTerm.radiusSymbol == nil ? pow(rightConstant / xTerm.coefficient, 1 / n) : 1
        let radiusY = yTerm.radiusSymbol == nil ? pow(rightConstant / yTerm.coefficient, 1 / n) : 1
        guard radiusX.isFinite, radiusY.isFinite, radiusX > 0, radiusY > 0 else { return nil }

        let curve = ParametricCurveDefinition(
            kind: .superellipse,
            centerX: xTerm.center,
            centerY: yTerm.center,
            radiusX: radiusX,
            radiusY: radiusY,
            exponent: n,
            radiusXSymbol: xTerm.radiusSymbol,
            radiusYSymbol: yTerm.radiusSymbol,
            exponentSymbol: xTerm.exponentSymbol,
            focalParameter: nil,
            tMin: 0,
            tMax: 2 * Double.pi
        )

        return ParametricRewriteInfo(
            shapeKind: .superellipse,
            curve: curve,
            summary: "超椭圆参数化"
        )
    }

    private static func parseTerm(_ expression: AlgebraExpression) -> AxisTerm? {
        let factors = multiplicativeFactors(expression)
        var coefficient = 1.0
        var powerCandidate: AlgebraExpression?

        for factor in factors {
            if case .number(let value) = factor {
                coefficient *= value
            } else if powerCandidate == nil {
                powerCandidate = factor
            } else {
                return nil
            }
        }

        guard
            coefficient > 0,
            let powerCandidate,
            case .power(.function("abs", let inner), let exponentExpression) = powerCandidate,
            let exponent = parseExponent(exponentExpression),
            let normalized = normalizeAxisExpression(inner)
        else {
            return nil
        }

        return AxisTerm(
            variable: normalized.variable,
            center: normalized.center,
            coefficient: normalized.radiusSymbol == nil ? coefficient * pow(normalized.scale, exponent.value) : coefficient,
            exponent: exponent.value,
            exponentSymbol: exponent.symbol,
            radiusSymbol: normalized.radiusSymbol
        )
    }

    private static func parseExponent(_ expression: AlgebraExpression) -> (value: Double, symbol: String?)? {
        switch expression {
        case .number(let value):
            return (value, nil)
        case .symbol(let name) where !["x", "y", "pi", "e"].contains(name):
            return (2, name)
        default:
            return nil
        }
    }

    private static func normalizeAxisExpression(_ expression: AlgebraExpression) -> (variable: String, center: Double, scale: Double, radiusSymbol: String?)? {
        switch expression {
        case .symbol(let name) where name == "x" || name == "y":
            return (name, 0, 1, nil)
        case .divide(let numerator, .number(let denominator)) where denominator != 0:
            guard let normalized = normalizeAxisExpression(numerator) else { return nil }
            return (normalized.variable, normalized.center, normalized.scale / abs(denominator), normalized.radiusSymbol)
        case .divide(let numerator, .symbol(let denominatorName)) where !["x", "y", "pi", "e"].contains(denominatorName):
            guard let normalized = normalizeAxisExpression(numerator), normalized.radiusSymbol == nil else { return nil }
            return (normalized.variable, normalized.center, normalized.scale, denominatorName)
        case .multiply(let factors):
            var scale = 1.0
            var rest: [AlgebraExpression] = []
            for factor in factors {
                if case .number(let value) = factor {
                    scale *= abs(value)
                } else {
                    rest.append(factor)
                }
            }
            guard rest.count == 1, let normalized = normalizeAxisExpression(rest[0]) else { return nil }
            return (normalized.variable, normalized.center, normalized.scale * scale, normalized.radiusSymbol)
        case .add(let terms):
            var variableName: String?
            var constant = 0.0
            for term in terms {
                switch term {
                case .symbol(let name) where name == "x" || name == "y":
                    variableName = name
                case .number(let value):
                    constant += value
                case .multiply(let factors):
                    guard
                        factors.count == 2,
                        case .number(let coefficient) = factors[0],
                        case .symbol(let name) = factors[1],
                        abs(coefficient - 1) < 0.000001,
                        name == "x" || name == "y"
                    else {
                        return nil
                    }
                    variableName = name
                default:
                    return nil
                }
            }
            guard let variableName else { return nil }
            return (variableName, -constant, 1, nil)
        default:
            return nil
        }
    }

    private static func additiveTerms(_ expression: AlgebraExpression) -> [AlgebraExpression] {
        if case .add(let terms) = expression {
            return terms
        }
        return [expression]
    }

    private static func multiplicativeFactors(_ expression: AlgebraExpression) -> [AlgebraExpression] {
        if case .multiply(let factors) = expression {
            return factors
        }
        return [expression]
    }
}

private struct AxisTerm {
    public var variable: String
    public var center: Double
    public var coefficient: Double
    public var exponent: Double
    public var exponentSymbol: String?
    public var radiusSymbol: String?

    public var resolvedExponentForValidation: Double {
        exponentSymbol == nil ? exponent : 2
    }

    public func numericExponentMatches(_ other: AxisTerm) -> Bool {
        if exponentSymbol != nil || other.exponentSymbol != nil {
            return exponentSymbol == other.exponentSymbol
        }
        return abs(exponent - other.exponent) < 0.000001
    }
}
