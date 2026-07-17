import Foundation

public struct FormulaKeyboardFormulaSource: FormulaKeyboardPrimitive {
    public let latexSource: String

    public init(latexSource: String) throws {
        self.latexSource = try FormulaKeyboardIdentifier.validateIdentifier(latexSource)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let latexSource = try container.decode(String.self)
        try self.init(latexSource: latexSource)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(latexSource)
    }
}
