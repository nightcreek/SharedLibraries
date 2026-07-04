import Foundation

/// First-version public incremental input token.
///
/// These tokens are an additive facade over the existing editor action pipeline.
/// They do not replace the editor layer and are translated into existing editor
/// actions or session-level control flows such as undo/redo.
public enum MathInputToken: Hashable, Sendable {
    case char(String)
    case number(String)
    case op(String)
    case function(String)
    case template(MathInputTemplateToken)
    case control(MathInputControlToken)
}

public enum MathInputTemplateToken: String, Hashable, Sendable {
    case fraction
    case sqrt
    case superscript
    case `subscript`
    case parentheses
    case absoluteValue
}

public enum MathInputControlToken: String, Hashable, Sendable {
    case moveLeft
    case moveRight
    case moveUp
    case moveDown
    case nextSlot
    case previousSlot
    case deleteBackward
    case deleteForward
    case submit
    case cancel
    case undo
    case redo
}
