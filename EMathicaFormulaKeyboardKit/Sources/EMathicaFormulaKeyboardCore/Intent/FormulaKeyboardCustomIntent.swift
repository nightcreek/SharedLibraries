import Foundation

public struct FormulaKeyboardCustomIntent: FormulaKeyboardPrimitive {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) throws {
        self.namespace = try FormulaKeyboardIdentifier.normalizeIdentifier(namespace)
        self.name = try FormulaKeyboardIdentifier.normalizeIdentifier(name)
    }
}
