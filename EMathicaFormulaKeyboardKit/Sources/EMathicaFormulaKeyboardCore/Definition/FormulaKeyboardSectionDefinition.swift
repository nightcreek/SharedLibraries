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

    public init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case id
            case rows
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(FormulaKeyboardSectionIdentifier.self, forKey: .id)
        let rows = try container.decode([FormulaKeyboardRowDefinition].self, forKey: .rows)
        try self.init(id: id, rows: rows)
    }
}
