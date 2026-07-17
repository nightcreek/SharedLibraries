import EMathicaFormulaDisplayCore
import SwiftUI

public struct FormulaDisplayStyle {
    public var textColor: Color
    public var operatorColor: Color
    public var functionColor: Color
    public var rawTextColor: Color
    public var errorTextColor: Color
    public var cursorColor: Color
    public var placeholderStrokeColor: Color
    public var placeholderFillColor: Color
    public var fractionLineColor: Color
    public var radicalColor: Color
    public var delimiterColor: Color
    public var debugColor: Color
    public var baseFont: Font
    public var scriptScale: CGFloat

    public init(
        textColor: Color = .primary,
        operatorColor: Color = .primary,
        functionColor: Color = .primary,
        rawTextColor: Color = .primary,
        errorTextColor: Color = .red,
        cursorColor: Color = .accentColor,
        placeholderStrokeColor: Color = .secondary,
        placeholderFillColor: Color = .clear,
        fractionLineColor: Color = .primary,
        radicalColor: Color = .primary,
        delimiterColor: Color = .primary,
        debugColor: Color = .red.opacity(0.6),
        baseFont: Font = .system(size: FormulaLayoutMetrics.default.baseFontSize),
        scriptScale: CGFloat = FormulaLayoutMetrics.default.scriptScale
    ) {
        self.textColor = textColor
        self.operatorColor = operatorColor
        self.functionColor = functionColor
        self.rawTextColor = rawTextColor
        self.errorTextColor = errorTextColor
        self.cursorColor = cursorColor
        self.placeholderStrokeColor = placeholderStrokeColor
        self.placeholderFillColor = placeholderFillColor
        self.fractionLineColor = fractionLineColor
        self.radicalColor = radicalColor
        self.delimiterColor = delimiterColor
        self.debugColor = debugColor
        self.baseFont = baseFont
        self.scriptScale = scriptScale
    }

    public static var `default`: FormulaDisplayStyle {
        FormulaDisplayStyle()
    }
}
