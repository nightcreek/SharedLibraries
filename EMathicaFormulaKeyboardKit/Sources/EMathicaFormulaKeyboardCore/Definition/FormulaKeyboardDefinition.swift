import Foundation

public struct FormulaKeyboardDefinition: FormulaKeyboardPrimitive {
    public let metadata: FormulaKeyboardMetadata
    public let defaultPageID: FormulaKeyboardPageIdentifier
    public let pages: [FormulaKeyboardPageDefinition]

    public init(
        metadata: FormulaKeyboardMetadata,
        defaultPageID: FormulaKeyboardPageIdentifier,
        pages: [FormulaKeyboardPageDefinition]
    ) throws {
        self.metadata = metadata
        self.defaultPageID = defaultPageID
        self.pages = pages
        try FormulaKeyboardDefinitionValidator().validate(self)
    }
}
