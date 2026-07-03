import Foundation

public struct FormulaLayoutBox: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case sequence
        case text
        case placeholder
        case cursor
        case raw
    }

    public var kind: Kind
    public var frame: FormulaRect
    public var baseline: Double
    public var children: [FormulaLayoutBox]

    public init(
        kind: Kind,
        frame: FormulaRect,
        baseline: Double,
        children: [FormulaLayoutBox]
    ) {
        self.kind = kind
        self.frame = frame
        self.baseline = baseline
        self.children = children
    }
}
