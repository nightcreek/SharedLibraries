import Foundation

public struct FormulaKeyboardSectionIdentifier: FormulaKeyboardPrimitive {
    public let rawValue: String

    public init(rawValue: String) throws {
        self.rawValue = try FormulaKeyboardIdentifier.normalizeIdentifier(rawValue)
    }
}
