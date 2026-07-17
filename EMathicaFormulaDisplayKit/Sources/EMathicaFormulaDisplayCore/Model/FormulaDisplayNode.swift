import Foundation

public enum FormulaTextRole: Equatable, Sendable {
    case symbol
    case number
    case raw
}

public struct FormulaPiecewiseRow: Equatable, Sendable {
    public var expression: FormulaDisplayNode
    public var condition: FormulaDisplayNode

    public init(expression: FormulaDisplayNode, condition: FormulaDisplayNode) {
        self.expression = expression
        self.condition = condition
    }
}

public indirect enum FormulaDisplayNode: Equatable, Sendable {
    case sequence([FormulaDisplayNode])
    case text(String, role: FormulaTextRole)
    case operatorSymbol(String)
    case function(name: String, arguments: [FormulaDisplayNode])
    case fraction(numerator: FormulaDisplayNode, denominator: FormulaDisplayNode)
    case sqrt(radicand: FormulaDisplayNode)
    case superscript(base: FormulaDisplayNode, exponent: FormulaDisplayNode)
    case `subscript`(base: FormulaDisplayNode, subscriptNode: FormulaDisplayNode)
    case scriptPair(base: FormulaDisplayNode, subscriptNode: FormulaDisplayNode?, superscriptNode: FormulaDisplayNode?)
    case parentheses(content: FormulaDisplayNode)
    case absoluteValue(content: FormulaDisplayNode)
    case parametric2D(x: FormulaDisplayNode, y: FormulaDisplayNode, range: FormulaDisplayNode?)
    case piecewise(rows: [FormulaPiecewiseRow])
    case cursor
    case placeholder
    case raw(String)
    case error(FormulaDisplayErrorNode)
}
