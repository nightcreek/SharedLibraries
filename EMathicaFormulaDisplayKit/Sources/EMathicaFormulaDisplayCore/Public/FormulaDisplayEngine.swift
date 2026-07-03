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
        let rawValue = markup.rawValue

        let containsCursor = rawValue.contains(#"\cursor{}"#)
        let containsPlaceholder = rawValue.contains(#"\placeholder{}"#) || rawValue.contains("□")
        let visibleText = rawValue
            .replacingOccurrences(of: #"\cursor{}"#, with: "")
            .replacingOccurrences(of: #"\placeholder{}"#, with: "")
            .replacingOccurrences(of: "□", with: "")

        let estimatedWidth = max(
            metrics.minimumBoxSize.width,
            Double(max(visibleText.count, 1)) * max(metrics.baseFontSize * 0.6, 1)
        )
        let estimatedHeight = max(metrics.minimumBoxSize.height, metrics.baseFontSize * 1.4)
        let baseline = max(metrics.baseFontSize * 0.8, estimatedHeight * 0.5)
        let bounds = FormulaRect(
            origin: .zero,
            size: .init(width: estimatedWidth, height: estimatedHeight)
        )

        let layout = FormulaLayoutBox(
            kind: .sequence,
            frame: bounds,
            baseline: baseline,
            children: []
        )

        var elements: [FormulaRenderElement] = []
        if !visibleText.isEmpty {
            elements.append(
                .text(
                    .init(
                        text: visibleText,
                        role: .plain,
                        frame: bounds
                    )
                )
            )
        }

        var cursorRects: [FormulaRect] = []
        if containsCursor && options.cursorVisible {
            let cursorRect = FormulaRect(
                origin: .init(x: bounds.maxX, y: 0),
                size: .init(width: metrics.cursorWidth, height: estimatedHeight)
            )
            cursorRects.append(cursorRect)
            elements.append(.cursor(cursorRect))
        }

        var placeholderRects: [FormulaRect] = []
        if containsPlaceholder {
            let placeholderRect = FormulaRect(
                origin: .init(
                    x: max(0, bounds.maxX - metrics.placeholderWidth),
                    y: max(0, (estimatedHeight - metrics.placeholderHeight) / 2)
                ),
                size: .init(width: metrics.placeholderWidth, height: metrics.placeholderHeight)
            )
            placeholderRects.append(placeholderRect)
            elements.append(.placeholder(placeholderRect))
        }

        let hitRegions = [FormulaHitRegion(id: "root", bounds: bounds)]
        let debugFrames = options.debugFramesEnabled ? [bounds] : []
        if options.debugFramesEnabled {
            elements.append(.debugFrame(bounds))
        }

        let plan = FormulaRenderPlan(
            size: bounds.size,
            baseline: baseline,
            elements: elements,
            bounds: bounds,
            cursorRects: cursorRects,
            placeholderRects: placeholderRects,
            hitRegions: hitRegions,
            debugFrames: debugFrames,
            rootNode: node,
            rootLayoutBox: layout
        )

        FormulaDisplayInvariant.validate(plan: plan)
        return plan
    }
}
