import Foundation

public enum MathKeyboardKeyLabel: Equatable, Sendable {
    case text(String)
    case formulaMarkup(String)
    case system(String)
}

public enum MathKeyboardKeySize: Equatable, Sendable {
    case normal
    case wide
    case flexible(Double)
}

