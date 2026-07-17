import Foundation

public struct FormulaKeyLayoutHint: FormulaKeyboardPrimitive {
    public let widthWeight: Int

    public init(widthWeight: Int) throws {
        guard widthWeight > 0 else {
            throw FormulaKeyboardDefinitionError.invalidWidthWeight(widthWeight)
        }
        self.widthWeight = widthWeight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let widthWeight = try container.decode(Int.self)
        try self.init(widthWeight: widthWeight)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(widthWeight)
    }
}
