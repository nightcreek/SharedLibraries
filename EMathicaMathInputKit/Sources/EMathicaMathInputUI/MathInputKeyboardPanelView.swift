import EMathicaMathInputCore
import EMathicaThemeKit
import SwiftUI

struct MathInputKeyboardPanelView: View {
    let panel: MathKeyboardPanel
    let style: MathKeyboardStyle
    let onKeyPress: (MathKeyboardKey) -> Void

    var body: some View {
        VStack(spacing: style.spacing.rowSpacing) {
            ForEach(Array(panel.rows.enumerated()), id: \.offset) { _, row in
                MathInputKeyboardRowView(
                    row: row,
                    style: style,
                    onKeyPress: onKeyPress
                )
            }
        }
        .padding(.horizontal, style.spacing.backplatePaddingHorizontal)
        .padding(.top, style.spacing.backplatePaddingTop)
        .padding(.bottom, style.spacing.backplatePaddingBottom)
    }
}

private struct MathInputKeyboardRowView: View {
    let row: MathKeyboardRow
    let style: MathKeyboardStyle
    let onKeyPress: (MathKeyboardKey) -> Void

    var body: some View {
        GeometryReader { proxy in
            let spacing = style.spacing.keySpacing
            let totalWeight = row.keys.reduce(0.0) { $0 + widthWeight(for: $1.size) }
            let totalSpacing = spacing * Double(max(0, row.keys.count - 1))
            let usableWidth = max(0, proxy.size.width - totalSpacing)
            let unitWidth = totalWeight > 0 ? usableWidth / totalWeight : 0

            HStack(spacing: spacing) {
                ForEach(row.keys) { key in
                    MathInputKeyboardKeyView(key: key, style: style, action: onKeyPress)
                        .frame(
                            width: unitWidth * widthWeight(for: key.size),
                            height: style.spacing.keyMinHeight
                        )
                }
            }
        }
        .frame(height: style.spacing.keyMinHeight)
    }

    private func widthWeight(for size: MathKeyboardKeySize) -> Double {
        switch size {
        case .normal:
            return 1
        case .wide:
            return 1.6
        case .flexible(let weight):
            return max(0.5, weight)
        }
    }
}
