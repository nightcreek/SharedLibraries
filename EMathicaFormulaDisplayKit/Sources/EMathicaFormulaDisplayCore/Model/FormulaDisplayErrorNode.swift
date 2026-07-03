import Foundation

public struct FormulaDisplayErrorNode: Equatable, Sendable {
    public var kind: FormulaDisplayErrorKind
    public var rawText: String

    public init(kind: FormulaDisplayErrorKind, rawText: String) {
        self.kind = kind
        self.rawText = rawText
    }
}

public enum FormulaDisplayErrorKind: Equatable, Sendable {
    case unknownCommand
    case unsupportedCommand
    case unmatchedBrace
    case malformedFraction
    case malformedScript
    case unmatchedDelimiter
}
