import Foundation

public struct FormulaKeyboardRowDefinition: FormulaKeyboardPrimitive {
    public let id: FormulaKeyboardRowIdentifier
    public let keys: [FormulaKeyDefinition]

    public init(
        id: FormulaKeyboardRowIdentifier,
        keys: [FormulaKeyDefinition]
    ) throws {
        guard !keys.isEmpty else {
            throw FormulaKeyboardDefinitionError.emptyKeys(rowID: id)
        }
        self.id = id
        self.keys = keys
    }
}
