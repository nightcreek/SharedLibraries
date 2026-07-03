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
        let visibleText = visibleText(from: node)

        let containsCursor = containsCursor(in: node)
        let containsPlaceholder = containsPlaceholder(in: node)

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
                        role: .raw,
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

    private func visibleText(from node: FormulaDisplayNode) -> String {
        switch node {
        case .sequence(let items):
            return items.map(visibleText(from:)).joined()
        case .text(let value, _):
            return value
        case .operatorSymbol(let value):
            return value
        case .function(let name, let arguments):
            let joinedArguments = arguments.map(visibleText(from:)).joined(separator: ",")
            return "\(name)(\(joinedArguments))"
        case .fraction(let numerator, let denominator):
            return "\(visibleText(from: numerator))/\(visibleText(from: denominator))"
        case .sqrt(let radicand):
            return "sqrt(\(visibleText(from: radicand)))"
        case .superscript(let base, let exponent):
            return "\(visibleText(from: base))^\(visibleText(from: exponent))"
        case .subscript(let base, let subscriptNode):
            return "\(visibleText(from: base))_\(visibleText(from: subscriptNode))"
        case .scriptPair(let base, let subscriptNode, let superscriptNode):
            var result = visibleText(from: base)
            if let subscriptNode {
                result += "_\(visibleText(from: subscriptNode))"
            }
            if let superscriptNode {
                result += "^\(visibleText(from: superscriptNode))"
            }
            return result
        case .parentheses(let content):
            return "(\(visibleText(from: content)))"
        case .absoluteValue(let content):
            return "|\(visibleText(from: content))|"
        case .cursor, .placeholder:
            return ""
        case .raw(let value):
            return value
        case .error(let error):
            return error.rawText
        }
    }

    private func containsCursor(in node: FormulaDisplayNode) -> Bool {
        switch node {
        case .cursor:
            return true
        case .sequence(let items):
            return items.contains(where: containsCursor(in:))
        case .function(_, let arguments):
            return arguments.contains(where: containsCursor(in:))
        case .fraction(let numerator, let denominator):
            return containsCursor(in: numerator) || containsCursor(in: denominator)
        case .sqrt(let radicand):
            return containsCursor(in: radicand)
        case .superscript(let base, let exponent):
            return containsCursor(in: base) || containsCursor(in: exponent)
        case .subscript(let base, let subscriptNode):
            return containsCursor(in: base) || containsCursor(in: subscriptNode)
        case .scriptPair(let base, let subscriptNode, let superscriptNode):
            return containsCursor(in: base)
                || subscriptNode.map { containsCursor(in: $0) } == true
                || superscriptNode.map { containsCursor(in: $0) } == true
        case .parentheses(let content), .absoluteValue(let content):
            return containsCursor(in: content)
        case .text, .operatorSymbol, .placeholder, .raw, .error:
            return false
        }
    }

    private func containsPlaceholder(in node: FormulaDisplayNode) -> Bool {
        switch node {
        case .placeholder:
            return true
        case .sequence(let items):
            return items.contains(where: containsPlaceholder(in:))
        case .function(_, let arguments):
            return arguments.contains(where: containsPlaceholder(in:))
        case .fraction(let numerator, let denominator):
            return containsPlaceholder(in: numerator) || containsPlaceholder(in: denominator)
        case .sqrt(let radicand):
            return containsPlaceholder(in: radicand)
        case .superscript(let base, let exponent):
            return containsPlaceholder(in: base) || containsPlaceholder(in: exponent)
        case .subscript(let base, let subscriptNode):
            return containsPlaceholder(in: base) || containsPlaceholder(in: subscriptNode)
        case .scriptPair(let base, let subscriptNode, let superscriptNode):
            return containsPlaceholder(in: base)
                || subscriptNode.map { containsPlaceholder(in: $0) } == true
                || superscriptNode.map { containsPlaceholder(in: $0) } == true
        case .parentheses(let content), .absoluteValue(let content):
            return containsPlaceholder(in: content)
        case .text, .operatorSymbol, .cursor, .raw, .error:
            return false
        }
    }
}
