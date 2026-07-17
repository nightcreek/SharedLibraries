import Foundation

public enum FormulaKeyIntent: FormulaKeyboardPrimitive {
    case semanticToken(FormulaSemanticToken)
    case navigation(FormulaKeyboardNavigationIntent)
    case editing(FormulaKeyboardEditingIntent)
    case custom(FormulaKeyboardCustomIntent)
}
