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
        case .line(let rect):
            Rectangle()
                .fill(Color.primary)
                .frame(width: max(rect.size.width, 1), height: max(rect.size.height, 1))
                .position(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height / 2)
        case .radical(let rect):
            Path { path in
                let startX = rect.origin.x
                let startY = rect.maxY
                path.move(to: CGPoint(x: startX, y: startY - rect.size.height * 0.3))
                path.addLine(to: CGPoint(x: startX + rect.size.width * 0.2, y: startY))
                path.addLine(to: CGPoint(x: startX + rect.size.width * 0.4, y: rect.origin.y))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.origin.y))
            }
            .stroke(Color.primary, lineWidth: 1)
        case .cursor(let rect):
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: max(rect.size.width, 1), height: max(rect.size.height, 1))
                .position(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height / 2)
        case .placeholder(let rect):
            RoundedRectangle(cornerRadius: 2)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                .frame(width: max(rect.size.width, 1), height: max(rect.size.height, 1))
                .position(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height / 2)
        case .debugFrame(let rect):
            Rectangle()
                .stroke(Color.red.opacity(0.6), lineWidth: 1)
                .frame(width: max(rect.size.width, 1), height: max(rect.size.height, 1))
                .position(x: rect.origin.x + rect.size.width / 2, y: rect.origin.y + rect.size.height / 2)
        }
    }
}
