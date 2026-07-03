import EMathicaFormulaDisplayCore
import SwiftUI

public struct FormulaDisplayView: View {
    private let plan: FormulaRenderPlan
    private let style: FormulaDisplayStyle
    private let showsCursor: Bool
    private let showsDebugFrames: Bool

    public init(markup: FormulaDisplayMarkup) {
        self.init(
            markup: markup,
            style: .default,
            options: .default,
            metrics: .default
        )
    }

    public init(rawValue: String) {
        self.init(
            rawValue: rawValue,
            style: .default,
            options: .default,
            metrics: .default
        )
    }

    public init(plan: FormulaRenderPlan) {
        self.init(plan: plan, style: .default)
    }

    public init(
        markup: FormulaDisplayMarkup,
        style: FormulaDisplayStyle = .default,
        options: FormulaDisplayOptions = .default,
        metrics: FormulaLayoutMetrics = .default
    ) {
        self.plan = FormulaDisplayEngine(options: options, metrics: metrics).getPlan(from: markup)
        self.style = style
        self.showsCursor = options.cursorVisible
        self.showsDebugFrames = options.debugFramesEnabled
    }

    public init(
        rawValue: String,
        style: FormulaDisplayStyle = .default,
        options: FormulaDisplayOptions = .default,
        metrics: FormulaLayoutMetrics = .default
    ) {
        self.init(
            markup: FormulaDisplayMarkup(rawValue: rawValue),
            style: style,
            options: options,
            metrics: metrics
        )
    }

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
        FormulaRenderPlanView(
            plan: plan,
            style: style,
            showsCursor: showsCursor,
            showsDebugFrames: showsDebugFrames
        )
    }
}
