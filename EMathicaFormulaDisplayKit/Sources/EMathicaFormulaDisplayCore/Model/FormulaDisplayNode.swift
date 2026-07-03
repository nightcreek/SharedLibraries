import Foundation

public indirect enum FormulaDisplayNode: Equatable, Sendable {
    case sequence([FormulaDisplayNode])
    case text(String)
    case operatorSymbol(String)
    case function(name: String, arguments: [FormulaDisplayNode])
    case fraction(numerator: FormulaDisplayNode, denominator: FormulaDisplayNode)
    case sqrt(radicand: FormulaDisplayNode)
    case superscript(base: FormulaDisplayNode, exponent: FormulaDisplayNode)
    case subscriptNode(base: FormulaDisplayNode, subscriptNode: FormulaDisplayNode)
    case scriptPair(base: FormulaDisplayNode, subscriptNode: FormulaDisplayNode?, superscriptNode: FormulaDisplayNode?)
    case parentheses(FormulaDisplayNode)
    case absoluteValue(FormulaDisplayNode)
    case cursor
    case placeholder
    case raw(String)
    case error(FormulaDisplayErrorNode)
}
