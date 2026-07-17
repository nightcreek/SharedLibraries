import Foundation

public struct FormulaKeyboardMetadata: FormulaKeyboardPrimitive {
    public let id: FormulaKeyboardIdentifier
    public let name: String
    public let version: FormulaKeyboardVersion

    public init(
        id: FormulaKeyboardIdentifier,
        name: String,
        version: FormulaKeyboardVersion
    ) throws {
        self.id = id
        self.name = try FormulaKeyboardIdentifier.validateIdentifier(name)
        self.version = version
    }

    public init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case version
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(FormulaKeyboardIdentifier.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let version = try container.decode(FormulaKeyboardVersion.self, forKey: .version)
        try self.init(id: id, name: name, version: version)
    }
}
