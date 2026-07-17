import EMathicaFormulaDisplayCore
import SwiftUI

struct FormulaPlaceholderOverlay: View {
    let rect: CGRect
    let strokeColor: Color
    let fillColor: Color

    init(rect: CGRect, strokeColor: Color, fillColor: Color) {
        self.rect = rect
        self.strokeColor = strokeColor
        self.fillColor = fillColor
    }

    init(anchor: FormulaPlaceholderAnchor, strokeColor: Color, fillColor: Color) {
        self.init(
            rect: Self.overlayRect(for: anchor),
            strokeColor: strokeColor,
            fillColor: fillColor
        )
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(strokeColor, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
            )
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .accessibilityHidden(true)
    }

    static func overlayRect(for anchor: FormulaPlaceholderAnchor) -> CGRect {
        let minHeight = max(anchor.ascent + anchor.descent, 10)
        let width = max(anchor.rect.size.width, 8)
        return CGRect(
            x: CGFloat(anchor.rect.origin.x),
            y: CGFloat(anchor.rect.origin.y),
            width: CGFloat(width),
            height: CGFloat(minHeight)
        )
    }

    private var cornerRadius: CGFloat {
        max(min(rect.height * 0.18, 6), 3)
    }
}
