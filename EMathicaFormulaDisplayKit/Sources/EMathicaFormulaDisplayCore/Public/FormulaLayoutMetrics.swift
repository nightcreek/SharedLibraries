import Foundation

public struct FormulaLayoutMetrics: Equatable, Sendable {
    public var baseFontSize: Double
    public var scriptScale: Double
    public var minimumFontSize: Double
    public var operatorSpacing: Double
    public var functionSpacing: Double
    public var fractionHorizontalPadding: Double
    public var fractionVerticalGap: Double
    public var fractionLineThickness: Double
    public var sqrtHorizontalPadding: Double
    public var sqrtOverlineGap: Double
    public var scriptVerticalRaise: Double
    public var subscriptVerticalDrop: Double
    public var delimiterHorizontalPadding: Double
    public var absoluteValueStrokeWidth: Double
    public var rawFallbackPadding: Double
    public var cursorWidth: Double
    public var placeholderWidth: Double
    public var placeholderHeight: Double
    public var minimumBoxSize: FormulaSize

    public init(
        baseFontSize: Double = 20,
        scriptScale: Double = 0.64,
        minimumFontSize: Double = 9,
        operatorSpacing: Double = 4,
        functionSpacing: Double = 4,
        fractionHorizontalPadding: Double = 8,
        fractionVerticalGap: Double = 6,
        fractionLineThickness: Double = 1,
        sqrtHorizontalPadding: Double = 6,
        sqrtOverlineGap: Double = 2,
        scriptVerticalRaise: Double = 12,
        subscriptVerticalDrop: Double = 8,
        delimiterHorizontalPadding: Double = 4,
        absoluteValueStrokeWidth: Double = 1,
        rawFallbackPadding: Double = 4,
        cursorWidth: Double = 2,
        placeholderWidth: Double = 14,
        placeholderHeight: Double = 20,
        minimumBoxSize: FormulaSize = .init(width: 16, height: 24)
    ) {
        self.baseFontSize = baseFontSize
        self.scriptScale = scriptScale
        self.minimumFontSize = minimumFontSize
        self.operatorSpacing = operatorSpacing
        self.functionSpacing = functionSpacing
        self.fractionHorizontalPadding = fractionHorizontalPadding
        self.fractionVerticalGap = fractionVerticalGap
        self.fractionLineThickness = fractionLineThickness
        self.sqrtHorizontalPadding = sqrtHorizontalPadding
        self.sqrtOverlineGap = sqrtOverlineGap
        self.scriptVerticalRaise = scriptVerticalRaise
        self.subscriptVerticalDrop = subscriptVerticalDrop
        self.delimiterHorizontalPadding = delimiterHorizontalPadding
        self.absoluteValueStrokeWidth = absoluteValueStrokeWidth
        self.rawFallbackPadding = rawFallbackPadding
        self.cursorWidth = cursorWidth
        self.placeholderWidth = placeholderWidth
        self.placeholderHeight = placeholderHeight
        self.minimumBoxSize = minimumBoxSize
    }

    public static let `default` = FormulaLayoutMetrics()

    public func scaledForScript() -> FormulaLayoutMetrics {
        let scaledFontSize = max(minimumFontSize, baseFontSize * scriptScale)
        let scale = scaledFontSize / max(baseFontSize, 1)
        return FormulaLayoutMetrics(
            baseFontSize: scaledFontSize,
            scriptScale: scriptScale,
            minimumFontSize: minimumFontSize,
            operatorSpacing: operatorSpacing * scale,
            functionSpacing: functionSpacing * scale,
            fractionHorizontalPadding: fractionHorizontalPadding * scale,
            fractionVerticalGap: fractionVerticalGap * scale,
            fractionLineThickness: max(1, fractionLineThickness * scale),
            sqrtHorizontalPadding: sqrtHorizontalPadding * scale,
            sqrtOverlineGap: sqrtOverlineGap * scale,
            scriptVerticalRaise: scriptVerticalRaise * scale,
            subscriptVerticalDrop: subscriptVerticalDrop * scale,
            delimiterHorizontalPadding: delimiterHorizontalPadding * scale,
            absoluteValueStrokeWidth: max(1, absoluteValueStrokeWidth * scale),
            rawFallbackPadding: rawFallbackPadding * scale,
            cursorWidth: max(1, cursorWidth * scale),
            placeholderWidth: placeholderWidth * scale,
            placeholderHeight: placeholderHeight * scale,
            minimumBoxSize: .init(
                width: minimumBoxSize.width * scale,
                height: minimumBoxSize.height * scale
            )
        )
    }
}
