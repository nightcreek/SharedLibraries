import Foundation

public enum FormulaFontRole: Sendable, Equatable {
    case standard
    case handwrittenResult
    case decorative
}

public enum FormulaRenderingBackend: Sendable, Equatable {
    case legacy
    case swiftMath
}
