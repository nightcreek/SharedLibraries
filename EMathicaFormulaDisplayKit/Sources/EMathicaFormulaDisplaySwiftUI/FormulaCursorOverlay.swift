import EMathicaFormulaDisplayCore
import SwiftUI

struct FormulaCursorOverlay: View {
    let state: FormulaCursorState
    let color: Color
    let opacity: Double

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(
                width: Self.cursorRect(for: state).width,
                height: Self.cursorRect(for: state).height
            )
            .offset(
                x: Self.cursorRect(for: state).minX,
                y: Self.cursorRect(for: state).minY
            )
            .opacity(opacity)
            .animation(.easeInOut(duration: 0.18), value: opacity)
            .accessibilityHidden(true)
    }

    static func cursorRect(for state: FormulaCursorState) -> CGRect {
        let anchor = state.insertionPoint
        let width = max(min(anchor.rect.size.width, 2), 1)
        let ascent = max(anchor.ascent, 1)
        let descent = max(anchor.descent, 0)
        return CGRect(
            x: CGFloat(anchor.x + max((anchor.rect.size.width - width) / 2, 0)),
            y: CGFloat(anchor.baseline - descent),
            width: CGFloat(width),
            height: CGFloat(ascent + descent)
        )
    }
}
