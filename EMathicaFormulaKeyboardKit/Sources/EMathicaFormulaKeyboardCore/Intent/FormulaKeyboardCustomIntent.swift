import Foundation

public struct FormulaKeyboardCustomIntent: FormulaKeyboardPrimitive {
    public let namespace: String
    public let name: String

    public init(namespace: String, name: String) throws {
        self.namespace = try FormulaKeyboardIdentifier.validateIdentifier(namespace)
        self.name = try FormulaKeyboardIdentifier.validateIdentifier(name)
    }

    public init(from decoder: Decoder) throws {
        enum CodingKeys: String, CodingKey {
            case namespace
            case name
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let namespace = try container.decode(String.self, forKey: .namespace)
        let name = try container.decode(String.self, forKey: .name)
        try self.init(namespace: namespace, name: name)
    }
}
