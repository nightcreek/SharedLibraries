import Foundation

public struct FormulaKeyboardIdentifier: FormulaKeyboardPrimitive {
    public let rawValue: String

    public init(rawValue: String) throws {
        self.rawValue = try FormulaKeyboardIdentifier.validateIdentifier(rawValue)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        try self.init(rawValue: rawValue)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    static func validateIdentifier(_ rawValue: String) throws -> String {
        guard !rawValue.isEmpty else {
            throw FormulaKeyboardDefinitionError.invalidIdentifier(rawValue)
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard rawValue == trimmed, !trimmed.isEmpty else {
            throw FormulaKeyboardDefinitionError.invalidIdentifier(rawValue)
        }

        return rawValue
    }
}
