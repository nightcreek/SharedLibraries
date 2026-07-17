import EMathicaFormulaDisplayCore
import EMathicaFormulaDisplaySwiftUI
import EMathicaMathInputCore
import EMathicaThemeKit
import SwiftUI

struct MathInputKeyboardLabelView: View {
    @Environment(\.colorScheme) private var colorScheme

    let label: MathKeyboardKeyLabel
    let style: MathKeyboardStyle
    let visualRole: MathInputKeyboardKeyVisualRole

    var body: some View {
        switch MathInputKeyboardStyleBridge.presentation(for: label) {
        case .formulaMarkup(let markup):
            FormulaDisplayView(
                rawValue: markup,
                style: MathInputKeyboardStyleBridge.formulaDisplayStyle(
                    baseColor: MathInputKeyboardStyleBridge.titleColor(for: visualRole, colorScheme: colorScheme),
                    role: visualRole,
                    style: style
                ),
                options: .init(debugFramesEnabled: false, cursorVisible: false),
                metrics: MathInputKeyboardStyleBridge.formulaLayoutMetrics(style: style, role: visualRole)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .allowsHitTesting(false)

        case .systemImage(let systemName):
            Image(systemName: systemName)
                .font(.system(size: style.typography.primaryFontSize, weight: .semibold))
                .foregroundStyle(MathInputKeyboardStyleBridge.titleColor(for: visualRole, colorScheme: colorScheme))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)

        case .plainText(let text):
            Text(text)
                .font(.system(size: style.typography.primaryFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(MathInputKeyboardStyleBridge.titleColor(for: visualRole, colorScheme: colorScheme))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
        }
    }
}
