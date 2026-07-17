import Foundation

public struct FormulaKeyboardRowIdentifier: FormulaKeyboardPrimitive {
    public let rawValue: String

    public init(rawValue: String) throws {
        self.rawValue = try FormulaKeyboardIdentifier.normalizeIdentifier(rawValue)
    }
}
