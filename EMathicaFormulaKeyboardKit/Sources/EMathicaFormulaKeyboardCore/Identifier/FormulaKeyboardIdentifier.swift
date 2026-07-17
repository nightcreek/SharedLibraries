import Foundation

public struct FormulaKeyboardIdentifier: FormulaKeyboardPrimitive {
    public let rawValue: String

    public init(rawValue: String) throws {
        self.rawValue = try FormulaKeyboardIdentifier.normalizeIdentifier(rawValue)
    }

    static func normalizeIdentifier(_ rawValue: String) throws -> String {
        let normalized = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            throw FormulaKeyboardDefinitionError.invalidIdentifier(rawValue)
        }
        return normalized
    }
}
