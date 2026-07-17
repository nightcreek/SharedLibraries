import Foundation

public struct FormulaLayoutID: Equatable, Hashable, Sendable {
    public var rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct FormulaLayoutChild: Equatable, Sendable {
    public var box: FormulaLayoutBox
    public var origin: FormulaPoint

    public init(box: FormulaLayoutBox, origin: FormulaPoint) {
        self.box = box
        self.origin = origin
    }
}

public struct FormulaLayoutBox: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case sequence
        case text
        case operatorSymbol
        case function
        case fraction
        case sqrt
        case superscript
        case `subscript`
        case scriptPair
        case parentheses
        case absoluteValue
        case parametric2D
        case piecewise
        case placeholder
        case cursor
        case insertionMarker
        case raw
        case error
    }

    public var id: FormulaLayoutID
    public var kind: Kind
    public var size: FormulaSize
    public var baseline: Double
    public var children: [FormulaLayoutChild]
    public var bounds: FormulaRect
    public var textContent: String?
    public var textRole: FormulaTextRole?

    public init(
        id: FormulaLayoutID,
        kind: Kind,
        size: FormulaSize,
        baseline: Double,
        children: [FormulaLayoutChild],
        bounds: FormulaRect,
        textContent: String? = nil,
        textRole: FormulaTextRole? = nil
    ) {
        self.id = id
        self.kind = kind
        self.size = size
        self.baseline = baseline
        self.children = children
        self.bounds = bounds
        self.textContent = textContent
        self.textRole = textRole
    }
}
