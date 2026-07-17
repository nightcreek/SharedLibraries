import Foundation

public struct FormulaKeyboardFormulaSource: FormulaKeyboardPrimitive {
    public let latexSource: String

    public init(latexSource: String) throws {
        self.latexSource = try FormulaKeyboardIdentifier.normalizeIdentifier(latexSource)
    }
}
