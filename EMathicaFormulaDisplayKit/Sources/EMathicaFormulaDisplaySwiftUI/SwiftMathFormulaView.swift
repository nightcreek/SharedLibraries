import EMathicaFormulaDisplayCore
import SwiftUI

public struct SwiftMathFormulaView: View {
    private let markup: FormulaDisplayMarkup
    private let fontRole: FormulaFontRole
    private let fontSize: CGFloat
    private let foregroundColor: Color
    private let style: FormulaDisplayStyle

    public init(
        markup: FormulaDisplayMarkup,
        fontRole: FormulaFontRole = .standard,
        fontSize: CGFloat,
        foregroundColor: Color = .primary
    ) {
        self.markup = markup
        self.fontRole = fontRole
        self.fontSize = fontSize
        self.foregroundColor = foregroundColor
        self.style = .init(
            textColor: foregroundColor,
            operatorColor: foregroundColor,
            functionColor: foregroundColor,
            rawTextColor: foregroundColor,
            errorTextColor: .red,
            cursorColor: .accentColor,
            placeholderStrokeColor: .secondary,
            placeholderFillColor: .clear,
            fractionLineColor: foregroundColor,
            radicalColor: foregroundColor,
            delimiterColor: foregroundColor,
            debugColor: .red.opacity(0.6),
            baseFont: .system(size: fontSize),
            scriptScale: FormulaLayoutMetrics.default.scriptScale
        )
    }

    public var body: some View {
        let options = FormulaDisplayOptions(
            debugFramesEnabled: false,
            cursorVisible: false,
            renderingBackend: .swiftMath,
            fontRole: fontRole
        )
        let metrics = FormulaLayoutMetrics(baseFontSize: fontSize)
        FormulaDisplayView(
            markup: markup,
            style: style,
            options: options,
            metrics: metrics
        )
    }
}
