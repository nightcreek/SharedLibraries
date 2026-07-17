import EMathicaFormulaDisplayCore
import SwiftUI

struct FormulaPlaceholderOverlay: View {
    let anchor: FormulaPlaceholderAnchor
    let strokeColor: Color
    let fillColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            )
            .frame(width: overlayRect.width, height: overlayRect.height)
            .offset(x: overlayRect.minX, y: overlayRect.minY)
            .accessibilityHidden(true)
    }

    private var overlayRect: CGRect {
        let minHeight = max(anchor.ascent + anchor.descent, 10)
        let width = max(anchor.rect.size.width, 8)
        return CGRect(
            x: CGFloat(anchor.rect.origin.x),
            y: CGFloat(anchor.baseline - anchor.descent),
            width: CGFloat(width),
            height: CGFloat(minHeight)
        )
    }

    private var cornerRadius: CGFloat {
        max(min(overlayRect.height * 0.18, 6), 3)
    }
}
