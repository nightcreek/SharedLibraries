import Foundation

public struct FormulaLayoutMetrics: Equatable, Sendable {
    public var baseFontSize: Double
    public var scriptScale: Double
    public var operatorSpacing: Double
    public var functionSpacing: Double
    public var fractionHorizontalPadding: Double
    public var fractionVerticalGap: Double
    public var fractionLineThickness: Double
    public var sqrtHorizontalPadding: Double
    public var sqrtOverlineGap: Double
    public var cursorWidth: Double
    public var placeholderWidth: Double
    public var placeholderHeight: Double
    public var minimumBoxSize: FormulaSize

    public init(
        baseFontSize: Double = 20,
        scriptScale: Double = 0.75,
        operatorSpacing: Double = 4,
        functionSpacing: Double = 4,
        fractionHorizontalPadding: Double = 8,
        fractionVerticalGap: Double = 6,
        fractionLineThickness: Double = 1,
        sqrtHorizontalPadding: Double = 6,
        sqrtOverlineGap: Double = 2,
        cursorWidth: Double = 2,
        placeholderWidth: Double = 14,
        placeholderHeight: Double = 20,
        minimumBoxSize: FormulaSize = .init(width: 16, height: 24)
    ) {
        self.baseFontSize = baseFontSize
        self.scriptScale = scriptScale
        self.operatorSpacing = operatorSpacing
        self.functionSpacing = functionSpacing
        self.fractionHorizontalPadding = fractionHorizontalPadding
        self.fractionVerticalGap = fractionVerticalGap
        self.fractionLineThickness = fractionLineThickness
        self.sqrtHorizontalPadding = sqrtHorizontalPadding
        self.sqrtOverlineGap = sqrtOverlineGap
        self.cursorWidth = cursorWidth
        self.placeholderWidth = placeholderWidth
        self.placeholderHeight = placeholderHeight
        self.minimumBoxSize = minimumBoxSize
    }

    public static let `default` = FormulaLayoutMetrics()
}
