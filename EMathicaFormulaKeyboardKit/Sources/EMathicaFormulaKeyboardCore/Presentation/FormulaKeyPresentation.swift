import Foundation

public enum FormulaKeyPresentation: FormulaKeyboardPrimitive {
    case text(FormulaKeyboardText)
    case symbol(FormulaKeyboardSymbol)
    case formulaSource(FormulaKeyboardFormulaSource)
}
