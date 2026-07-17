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

    public init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case id
            case keys
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(FormulaKeyboardRowIdentifier.self, forKey: .id)
        let keys = try container.decode([FormulaKeyDefinition].self, forKey: .keys)
        try self.init(id: id, keys: keys)
    }
}
