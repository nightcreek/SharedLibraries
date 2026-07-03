import EMathicaFormulaDisplayCore
import SwiftUI

public struct FormulaDisplayView: View {
    private let plan: FormulaRenderPlan

    public init(markup: FormulaDisplayMarkup) {
        self.plan = FormulaDisplayEngine().getPlan(from: markup)
    }

    public init(rawValue: String) {
        self.plan = FormulaDisplayEngine().getPlan(from: FormulaDisplayMarkup(rawValue: rawValue))
    }

    public init(plan: FormulaRenderPlan) {
        self.plan = plan
    }

    public var body: some View {
        FormulaRenderPlanView(plan: plan)
    }
}
