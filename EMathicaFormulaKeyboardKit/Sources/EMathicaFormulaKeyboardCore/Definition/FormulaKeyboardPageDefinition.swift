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

    public init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case id
            case sections
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(FormulaKeyboardPageIdentifier.self, forKey: .id)
        let sections = try container.decode([FormulaKeyboardSectionDefinition].self, forKey: .sections)
        try self.init(id: id, sections: sections)
    }
}
