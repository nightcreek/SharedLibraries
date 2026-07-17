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

public struct FormulaGridRow: Equatable, Sendable {
    public var cells: [FormulaDisplayNode]

    public init(cells: [FormulaDisplayNode]) {
        self.cells = cells
    }
}

public enum FormulaMatrixEnvironment: Equatable, Sendable {
    case matrix
    case pmatrix
    case bmatrix
    case vmatrix
    case Vmatrix
    case smallmatrix
}

public enum FormulaAccentStyle: Equatable, Sendable {
    case vector
    case overline
    case hat
}

public enum FormulaLargeOperatorKind: Equatable, Sendable {
    case sum
    case product
}

public indirect enum FormulaDisplayNode: Equatable, Sendable {
    case sequence([FormulaDisplayNode])
    case text(String, role: FormulaTextRole)
    case operatorSymbol(String)
    case function(name: String, arguments: [FormulaDisplayNode])
    case fraction(numerator: FormulaDisplayNode, denominator: FormulaDisplayNode)
    case sqrt(radicand: FormulaDisplayNode)
    case nthRoot(index: FormulaDisplayNode, radicand: FormulaDisplayNode)
    case superscript(base: FormulaDisplayNode, exponent: FormulaDisplayNode)
    case `subscript`(base: FormulaDisplayNode, subscriptNode: FormulaDisplayNode)
    case scriptPair(base: FormulaDisplayNode, subscriptNode: FormulaDisplayNode?, superscriptNode: FormulaDisplayNode?)
    case parentheses(content: FormulaDisplayNode)
    case brackets(content: FormulaDisplayNode)
    case braces(content: FormulaDisplayNode)
    case absoluteValue(content: FormulaDisplayNode)
    case accent(style: FormulaAccentStyle, content: FormulaDisplayNode)
    case matrix(environment: FormulaMatrixEnvironment, rows: [FormulaGridRow])
    case cases(rows: [FormulaGridRow])
    case limit(variable: FormulaDisplayNode, target: FormulaDisplayNode, body: FormulaDisplayNode)
    case largeOperator(
        kind: FormulaLargeOperatorKind,
        variable: FormulaDisplayNode,
        lowerBound: FormulaDisplayNode,
        upperBound: FormulaDisplayNode,
        body: FormulaDisplayNode
    )
    case integral(
        lowerBound: FormulaDisplayNode,
        upperBound: FormulaDisplayNode,
        integrand: FormulaDisplayNode,
        variable: FormulaDisplayNode
    )
    case parametric2D(x: FormulaDisplayNode, y: FormulaDisplayNode, range: FormulaDisplayNode?)
    case parametric3D(x: FormulaDisplayNode, y: FormulaDisplayNode, z: FormulaDisplayNode)
    case piecewise(rows: [FormulaPiecewiseRow])
    case cursor(FormulaDisplayCursorToken)
    case placeholder(FormulaDisplayPlaceholderToken)
    case raw(String)
    case error(FormulaDisplayErrorNode)
}

public extension FormulaDisplayNode {
    static var anonymousCursor: Self {
        .cursor(.anonymous)
    }

    static var anonymousPlaceholder: Self {
        .placeholder(.anonymous)
    }
}
