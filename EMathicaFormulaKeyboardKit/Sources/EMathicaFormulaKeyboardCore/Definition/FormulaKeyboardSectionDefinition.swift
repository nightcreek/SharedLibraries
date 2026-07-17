import Foundation

public struct FormulaKeyboardSectionDefinition: FormulaKeyboardPrimitive {
    public let id: FormulaKeyboardSectionIdentifier
    public let rows: [FormulaKeyboardRowDefinition]

    public init(
        id: FormulaKeyboardSectionIdentifier,
        rows: [FormulaKeyboardRowDefinition]
    ) throws {
        guard !rows.isEmpty else {
            throw FormulaKeyboardDefinitionError.emptyRows(sectionID: id)
        }
        self.id = id
        self.rows = rows
    }
}
