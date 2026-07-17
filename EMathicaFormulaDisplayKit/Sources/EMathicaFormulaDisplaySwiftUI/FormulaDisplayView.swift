import EMathicaFormulaDisplayCore
import SwiftUI

public struct FormulaDisplayView: View {
    private enum Storage {
        case legacy(plan: FormulaRenderPlan, showsCursor: Bool, showsDebugFrames: Bool)
        case swiftMath(snapshot: FormulaSwiftMathSnapshot?, error: FormulaSwiftMathRenderError?)
    }

    private let storage: Storage
    private let style: FormulaDisplayStyle

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
        self.style = style
        let color = style.textColor.resolvedFormulaRGBA()
        switch FormulaDisplayContentResolver.resolve(
            markup: markup,
            options: options,
            metrics: metrics,
            foregroundColor: color
        ) {
        case .legacy(let plan):
            self.storage = .legacy(
                plan: plan,
                showsCursor: options.cursorVisible,
                showsDebugFrames: options.debugFramesEnabled
            )
        case .swiftMath(let snapshot):
            self.storage = .swiftMath(snapshot: snapshot, error: nil)
        case .swiftMathError(let error):
            self.storage = .swiftMath(snapshot: nil, error: error)
        }
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
        self.storage = .legacy(
            plan: plan,
            showsCursor: showsCursor,
            showsDebugFrames: showsDebugFrames
        )
        self.style = style
    }

    public var body: some View {
        switch storage {
        case .legacy(let plan, let showsCursor, let showsDebugFrames):
            FormulaRenderPlanView(
                plan: plan,
                style: style,
                showsCursor: showsCursor,
                showsDebugFrames: showsDebugFrames
            )
        case .swiftMath(let snapshot, let error):
            FormulaSwiftMathSnapshotView(snapshot: snapshot, error: error, style: style)
        }
    }
}
