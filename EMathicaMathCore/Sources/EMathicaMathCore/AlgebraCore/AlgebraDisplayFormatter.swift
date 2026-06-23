import Foundation

public enum AlgebraDisplayFormatter {
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
            return name == "pi" ? "π" : name
        case .add(let terms):
            return terms.map(format).joined(separator: " + ").replacingOccurrences(of: "+ -", with: "- ")
        case .multiply(let factors):
            return factors.map { factor in
                if case .add = factor { return "(\(format(factor)))" }
                return format(factor)
            }.joined(separator: " ")
        case .divide(let numerator, let denominator):
            return "(\(format(numerator)))/(\(format(denominator)))"
        case .power(let base, let exponent):
            return "\(wrapPowerBase(base))\(formatExponent(exponent))"
        case .function(let name, let argument):
            if name == "abs" {
                return "|\(format(argument))|"
            }
            return "\(name)(\(format(argument)))"
        }
    }

    nonisolated private static func wrapPowerBase(_ expression: AlgebraExpression) -> String {
        switch expression {
        case .number, .symbol, .function:
            return format(expression)
        default:
            return "(\(format(expression)))"
        }
    }

    nonisolated private static func formatExponent(_ exponent: AlgebraExpression) -> String {
        switch exponent {
        case .number(let value):
            if let superscript = formatSuperscriptInteger(value) {
                return superscript
            }
            return "^(\(formatNumber(value)))"
        default:
            return "^(\(format(exponent)))"
        }
    }

    nonisolated private static func formatSuperscriptInteger(_ value: Double) -> String? {
        let rounded = value.rounded()
        guard abs(value - rounded) < 0.000001 else { return nil }

        let text = String(Int(rounded))
        let table: [Character: Character] = [
            "-": "⁻",
            "0": "⁰",
            "1": "¹",
            "2": "²",
            "3": "³",
            "4": "⁴",
            "5": "⁵",
            "6": "⁶",
            "7": "⁷",
            "8": "⁸",
            "9": "⁹"
        ]

        var result = ""
        for character in text {
            guard let mapped = table[character] else { return nil }
            result.append(mapped)
        }
        return result
    }

    nonisolated private static func formatNumber(_ value: Double) -> String {
        let rounded = (value * 1_000_000).rounded() / 1_000_000
        if rounded == Double(Int(rounded)) {
            return String(Int(rounded))
        }
        return String(rounded)
    }
}
