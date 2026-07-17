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
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: markup,
            options: options,
            metrics: metrics,
            foregroundColor: foregroundColor.resolvedFormulaRGBA()
        )

        switch resolved {
        case .legacy(let plan):
            FormulaRenderPlanView(
                plan: plan,
                style: style,
                showsCursor: false,
                showsDebugFrames: false
            )
        case .swiftMath(let snapshot):
            FormulaSwiftMathSnapshotView(snapshot: snapshot, error: nil, style: style)
        case .swiftMathError(let error):
            FormulaSwiftMathSnapshotView(snapshot: nil, error: error, style: style)
        }
    }
}
