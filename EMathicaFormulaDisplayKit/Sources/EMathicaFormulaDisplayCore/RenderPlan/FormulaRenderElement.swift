import Foundation

public struct FormulaTextElement: Equatable, Sendable {
    public enum Role: Equatable, Sendable {
        case plain
        case symbol
        case number
        case `operator`
        case raw
    }

    public var text: String
    public var role: Role
    public var frame: FormulaRect

    public init(text: String, role: Role, frame: FormulaRect) {
        self.text = text
        self.role = role
        self.frame = frame
    }
}

public enum FormulaRenderElement: Equatable, Sendable {
    case text(FormulaTextElement)
    case line(FormulaRect)
    case radical(FormulaRect)
    case cursor(FormulaRect)
    case placeholder(FormulaRect)
    case debugFrame(FormulaRect)
}
