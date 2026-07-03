import Foundation

public struct FormulaDisplayEngine: Sendable {
    public var options: FormulaDisplayOptions
    public var metrics: FormulaLayoutMetrics

    public init(
        options: FormulaDisplayOptions = .default,
        metrics: FormulaLayoutMetrics = .default
    ) {
        self.options = options
        self.metrics = metrics
    }

    public func getPlan(from markup: FormulaDisplayMarkup) -> FormulaRenderPlan {
        let parser = FormulaDisplayParser()
        let node = parser.parse(markup)
        let layout = FormulaLayoutEngine(metrics: metrics).layout(node)
        let builder = FormulaRenderPlanBuilder(metrics: metrics, options: options)
        return builder.build(from: layout, rootNode: node)
    }
}
