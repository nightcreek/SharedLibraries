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
        let visibleText = visibleText(from: node)
        let bounds = layout.bounds

        var elements: [FormulaRenderElement] = collectElements(from: layout, offset: .zero)
        if !visibleText.isEmpty && !elements.contains(where: {
            if case .text = $0 { return true }
            return false
        }) {
            elements.append(.text(.init(text: visibleText, role: .raw, frame: bounds)))
        }

        let cursorRects = options.cursorVisible ? collectRects(of: .cursor, from: layout, offset: .zero) : []
        let placeholderRects = collectRects(of: .placeholder, from: layout, offset: .zero)
        let hitRegions = collectHitRegions(from: layout, offset: .zero)
        let debugFrames = options.debugFramesEnabled ? collectDebugFrames(from: layout, offset: .zero) : []
        if options.debugFramesEnabled {
            elements.append(contentsOf: debugFrames.map { .debugFrame($0) })
        }

        let plan = FormulaRenderPlan(
            size: layout.size,
            baseline: layout.baseline,
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

    private func collectElements(from box: FormulaLayoutBox, offset: FormulaPoint) -> [FormulaRenderElement] {
        var result: [FormulaRenderElement] = []
        let globalBounds = box.bounds.offsetBy(dx: offset.x, dy: offset.y)
        switch box.kind {
        case .text, .operatorSymbol, .function, .raw, .error:
            let text = box.textContent ?? visibleText(from: box)
            if !text.isEmpty {
                let role: FormulaTextElement.Role
                switch box.kind {
                case .operatorSymbol:
                    role = .operator
                case .raw, .error:
                    role = .raw
                default:
                    role = .plain
                }
                result.append(.text(.init(text: text, role: role, frame: globalBounds)))
            }
        case .cursor:
            result.append(.cursor(globalBounds))
        case .placeholder:
            result.append(.placeholder(globalBounds))
        case .fraction, .sqrt, .sequence, .superscript, .subscript, .scriptPair, .parentheses, .absoluteValue:
            break
        }

        for child in box.children {
            result.append(contentsOf: collectElements(
                from: child.box,
                offset: .init(x: offset.x + child.origin.x, y: offset.y + child.origin.y)
            ))
        }
        return result
    }

    private func collectRects(of kind: FormulaLayoutBox.Kind, from box: FormulaLayoutBox, offset: FormulaPoint) -> [FormulaRect] {
        let globalBounds = box.bounds.offsetBy(dx: offset.x, dy: offset.y)
        var result: [FormulaRect] = box.kind == kind ? [globalBounds] : []
        for child in box.children {
            result.append(contentsOf: collectRects(
                of: kind,
                from: child.box,
                offset: .init(x: offset.x + child.origin.x, y: offset.y + child.origin.y)
            ))
        }
        return result
    }

    private func collectHitRegions(from box: FormulaLayoutBox, offset: FormulaPoint) -> [FormulaHitRegion] {
        let globalBounds = box.bounds.offsetBy(dx: offset.x, dy: offset.y)
        var result = [FormulaHitRegion(id: box.id.rawValue, bounds: globalBounds)]
        for child in box.children {
            result.append(contentsOf: collectHitRegions(
                from: child.box,
                offset: .init(x: offset.x + child.origin.x, y: offset.y + child.origin.y)
            ))
        }
        return result
    }

    private func collectDebugFrames(from box: FormulaLayoutBox, offset: FormulaPoint) -> [FormulaRect] {
        let globalBounds = box.bounds.offsetBy(dx: offset.x, dy: offset.y)
        var result = [globalBounds]
        for child in box.children {
            result.append(contentsOf: collectDebugFrames(
                from: child.box,
                offset: .init(x: offset.x + child.origin.x, y: offset.y + child.origin.y)
            ))
        }
        return result
    }

    private func visibleText(from box: FormulaLayoutBox) -> String {
        if let textContent = box.textContent {
            return textContent
        }
        if box.children.isEmpty {
            return ""
        }
        return box.children.map { visibleText(from: $0.box) }.joined()
    }
}
