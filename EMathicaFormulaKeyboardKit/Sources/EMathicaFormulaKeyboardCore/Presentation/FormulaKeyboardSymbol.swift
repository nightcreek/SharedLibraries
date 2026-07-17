import Foundation

public struct FormulaKeyboardSymbol: FormulaKeyboardPrimitive {
    public let rawValue: String

    public init(rawValue: String) throws {
        self.rawValue = try FormulaKeyboardIdentifier.normalizeIdentifier(rawValue)
    }
}
