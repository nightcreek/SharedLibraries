import Foundation

public struct FormulaKeyboardMetadata: FormulaKeyboardPrimitive {
    public let id: FormulaKeyboardIdentifier
    public let name: String
    public let version: FormulaKeyboardVersion

    public init(
        id: FormulaKeyboardIdentifier,
        name: String,
        version: FormulaKeyboardVersion
    ) {
        self.id = id
        self.name = name
        self.version = version
    }
}
