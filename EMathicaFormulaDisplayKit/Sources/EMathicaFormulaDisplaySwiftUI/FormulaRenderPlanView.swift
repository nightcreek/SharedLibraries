import EMathicaFormulaDisplayCore
import SwiftUI

public struct FormulaRenderPlanView: View {
    public let plan: FormulaRenderPlan
    public let style: FormulaDisplayStyle
    public let showsCursor: Bool
    public let showsDebugFrames: Bool

    public init(
        plan: FormulaRenderPlan,
        style: FormulaDisplayStyle = .default,
        showsCursor: Bool = true,
        showsDebugFrames: Bool = false
    ) {
        self.plan = plan
        self.style = style
        self.showsCursor = showsCursor
        self.showsDebugFrames = showsDebugFrames
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(filteredElements.enumerated()), id: \.offset) { _, element in
                FormulaRenderElementView(
                    element: element,
                    style: style,
                    showsCursor: showsCursor,
                    showsDebugFrames: showsDebugFrames
                )
            }
        }
        .frame(
            width: max(plan.size.width, 1),
            height: max(plan.size.height, 1),
            alignment: .topLeading
        )
    }

    private var filteredElements: [FormulaRenderElement] {
        plan.elements.filter { element in
            switch element {
            case .cursor:
                return showsCursor
            case .debugFrame:
                return showsDebugFrames
            default:
                return true
            }
        }
    }
}
