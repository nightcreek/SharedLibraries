import Foundation

public struct FormulaKeyLayoutHint: FormulaKeyboardPrimitive {
    public let widthWeight: Double

    public init(widthWeight: Double) throws {
        guard widthWeight.isFinite, widthWeight > 0 else {
            throw FormulaKeyboardDefinitionError.invalidWidthWeight(widthWeight)
        }
        self.widthWeight = widthWeight
    }
}
