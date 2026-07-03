import Foundation

public enum FormulaDisplayErrorNode: Equatable, Sendable {
    case unsupportedCommand(String)
    case malformedMarkup(String)
}
