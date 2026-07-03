import Foundation

public enum FormulaDisplayInvariant {
    public static func validate(plan: FormulaRenderPlan) {
        precondition(plan.size.width >= 0, "FormulaRenderPlan width must be nonnegative.")
        precondition(plan.size.height >= 0, "FormulaRenderPlan height must be nonnegative.")
        precondition(plan.baseline >= 0, "FormulaRenderPlan baseline must be nonnegative.")
        precondition(plan.bounds.size == plan.size, "FormulaRenderPlan bounds and size must agree.")
    }
}
