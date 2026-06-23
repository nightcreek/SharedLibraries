import Foundation

public enum AlgebraLatexFormatter {
    nonisolated static func format(_ relation: AlgebraRelation) -> String {
        switch relation {
        case .expression(let expression):
            return format(expression)
        case .equation(let equation):
            return "\(format(equation.left)) = \(format(equation.right))"
        }
    }

    nonisolated static func format(_ expression: AlgebraExpression) -> String {
        switch expression {
        case .number(let value):
            return formatNumber(value)
        case .symbol(let name):
            return name == "pi" ? "\\pi" : name
        case .add(let terms):
            return terms.map(format).joined(separator: " + ").replacingOccurrences(of: "+ -", with: "- ")
        case .multiply(let factors):
            return factors.map { factor in
                if case .add = factor { return "(\(format(factor)))" }
                return format(factor)
            }.joined(separator: " ")
        case .divide(let numerator, let denominator):
            return "\\frac{\(format(numerator))}{\(format(denominator))}"
        case .power(let base, let exponent):
            return "\(wrapPowerBase(base))^{\(format(exponent))}"
        case .function(let name, let argument):
            if name == "abs" {
                return "\\left|\(format(argument))\\right|"
            }
            return "\\\(name)\\left(\(format(argument))\\right)"
        }
    }

    nonisolated private static func wrapPowerBase(_ expression: AlgebraExpression) -> String {
        switch expression {
        case .number, .symbol, .function:
            return format(expression)
        default:
            return "\\left(\(format(expression))\\right)"
        }
    }

    nonisolated private static func formatNumber(_ value: Double) -> String {
        let rounded = (value * 1_000_000).rounded() / 1_000_000
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}
