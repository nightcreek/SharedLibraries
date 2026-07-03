import EMathicaFormulaDisplayCore
import SwiftUI

public struct FormulaRenderPlanView: View {
    public let plan: FormulaRenderPlan

    public init(plan: FormulaRenderPlan) {
        self.plan = plan
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(plan.elements.enumerated()), id: \.offset) { _, element in
                elementView(element)
            }
        }
        .frame(width: max(plan.size.width, 1), height: max(plan.size.height, 1), alignment: .topLeading)
    }

    @ViewBuilder
    private func elementView(_ element: FormulaRenderElement) -> some View {
        switch element {
        case .text(let text):
            Text(text.text)
                .font(.system(size: 16))
                .position(
                    x: text.frame.origin.x + (text.frame.size.width / 2),
                    y: text.frame.origin.y + (text.frame.size.height / 2)
                )
        case .line(let line):
            Rectangle()
                .fill(Color.primary)
                .frame(width: max(line.frame.size.width, 1), height: max(line.frame.size.height, 1))
                .position(x: line.frame.origin.x + line.frame.size.width / 2, y: line.frame.origin.y + line.frame.size.height / 2)
        case .radical(let radical):
            Path { path in
                let rect = radical.frame
                let startX = rect.origin.x
                let startY = rect.maxY
                path.move(to: CGPoint(x: startX, y: startY - rect.size.height * 0.3))
                path.addLine(to: CGPoint(x: startX + rect.size.width * 0.2, y: startY))
                path.addLine(to: CGPoint(x: startX + rect.size.width * 0.4, y: rect.origin.y))
                path.addLine(to: CGPoint(x: radical.overlineStart.x, y: radical.overlineStart.y))
                path.addLine(to: CGPoint(x: radical.overlineEnd.x, y: radical.overlineEnd.y))
            }
            .stroke(Color.primary, lineWidth: 1)
        case .cursor(let cursor):
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: max(cursor.frame.size.width, 1), height: max(cursor.frame.size.height, 1))
                .position(x: cursor.frame.origin.x + cursor.frame.size.width / 2, y: cursor.frame.origin.y + cursor.frame.size.height / 2)
        case .placeholder(let placeholder):
            RoundedRectangle(cornerRadius: 2)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                .frame(width: max(placeholder.frame.size.width, 1), height: max(placeholder.frame.size.height, 1))
                .position(x: placeholder.frame.origin.x + placeholder.frame.size.width / 2, y: placeholder.frame.origin.y + placeholder.frame.size.height / 2)
        case .debugFrame(let debugFrame):
            Rectangle()
                .stroke(Color.red.opacity(0.6), lineWidth: 1)
                .frame(width: max(debugFrame.frame.size.width, 1), height: max(debugFrame.frame.size.height, 1))
                .position(x: debugFrame.frame.origin.x + debugFrame.frame.size.width / 2, y: debugFrame.frame.origin.y + debugFrame.frame.size.height / 2)
        }
    }
}
