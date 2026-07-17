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
        operatorSpacing: Double = 3.6,
        functionSpacing: Double = 3.4,
        fractionHorizontalPadding: Double = 6.6,
        fractionVerticalGap: Double = 5.2,
        fractionLineThickness: Double = 0.9,
        sqrtHorizontalPadding: Double = 3.8,
        sqrtOverlineGap: Double = 2,
        scriptVerticalRaise: Double = 12,
        subscriptVerticalDrop: Double = 8,
        delimiterHorizontalPadding: Double = 3.1,
        absoluteValueStrokeWidth: Double = 0.7,
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
        let scaledPlaceholderWidth = max(placeholderWidth * scale, scaledFontSize * 0.78)
        let scaledPlaceholderHeight = max(placeholderHeight * scale, scaledFontSize * 1.02)
        let scaledMinimumSize = FormulaSize(
            width: max(minimumBoxSize.width * scale, scaledFontSize * 0.82),
            height: max(minimumBoxSize.height * scale, scaledFontSize * 1.06)
        )
        return FormulaLayoutMetrics(
            baseFontSize: scaledFontSize,
            scriptScale: scriptScale,
            minimumFontSize: minimumFontSize,
            operatorSpacing: operatorSpacing * scale,
            functionSpacing: functionSpacing * scale,
            fractionHorizontalPadding: fractionHorizontalPadding * scale,
            fractionVerticalGap: fractionVerticalGap * scale,
            fractionLineThickness: max(0.75, fractionLineThickness * scale),
            sqrtHorizontalPadding: sqrtHorizontalPadding * scale,
            sqrtOverlineGap: sqrtOverlineGap * scale,
            scriptVerticalRaise: scriptVerticalRaise * scale,
            subscriptVerticalDrop: subscriptVerticalDrop * scale,
            delimiterHorizontalPadding: delimiterHorizontalPadding * scale,
            absoluteValueStrokeWidth: max(0.7, absoluteValueStrokeWidth * scale),
            rawFallbackPadding: rawFallbackPadding * scale,
            cursorWidth: max(0.9, cursorWidth * scale),
            placeholderWidth: scaledPlaceholderWidth,
            placeholderHeight: scaledPlaceholderHeight,
            minimumBoxSize: scaledMinimumSize
        )
    }
}
