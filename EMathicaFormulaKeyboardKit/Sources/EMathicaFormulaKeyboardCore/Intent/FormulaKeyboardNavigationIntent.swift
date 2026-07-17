import Foundation

public enum FormulaKeyboardNavigationIntent: String, FormulaKeyboardPrimitive {
    case moveLeft
    case moveRight
    case moveUp
    case moveDown
    case tabForward
    case tabBackward
    case moveToLineStart
    case moveToLineEnd
    case pageUp
    case pageDown
}
