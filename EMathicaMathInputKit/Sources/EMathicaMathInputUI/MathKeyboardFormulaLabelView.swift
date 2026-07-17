import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import SwiftUI

struct MathKeyboardFormulaLabelView: View {
    let keyID: String
    let markup: String
    let fallbackText: String
    let style: FormulaDisplayStyle
    let metrics: FormulaLayoutMetrics

    private var probeResult: FormulaReadOnlyRenderProbeResult {
        FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: metrics
        )
    }

    var body: some View {
        switch probeResult {
        case .success:
            FormulaDisplayView(
                rawValue: markup,
                style: style,
                options: .init(
                    debugFramesEnabled: false,
                    cursorVisible: false,
                    renderingBackend: .swiftMath,
                    fontRole: .standard
                ),
                metrics: metrics
            )
            .fixedSize(horizontal: false, vertical: false)
        case .failure(_, let message):
            #if DEBUG
            Text("\(keyID)\n\(markup)\n\(message)")
                .font(.system(size: max(metrics.minimumFontSize - 1, 7), weight: .medium, design: .rounded))
                .foregroundStyle(style.errorTextColor)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.5)
            #else
            Text(fallbackText)
                .font(style.baseFont)
                .foregroundStyle(style.textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            #endif
        }
    }
}
