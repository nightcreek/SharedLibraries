import Foundation

public struct FormulaKeyIdentifier: FormulaKeyboardPrimitive {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
