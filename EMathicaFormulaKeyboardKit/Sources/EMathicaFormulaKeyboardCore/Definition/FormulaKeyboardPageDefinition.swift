import Foundation

public struct FormulaKeyboardPageDefinition: FormulaKeyboardPrimitive {
    public let id: FormulaKeyboardPageIdentifier
    public let sections: [FormulaKeyboardSectionDefinition]

    public init(
        id: FormulaKeyboardPageIdentifier,
        sections: [FormulaKeyboardSectionDefinition]
    ) throws {
        guard !sections.isEmpty else {
            throw FormulaKeyboardDefinitionError.emptySections(pageID: id)
        }
        self.id = id
        self.sections = sections
    }
}
