import Foundation

public struct FormulaRenderPlanBuilder: Sendable {
    public var metrics: FormulaLayoutMetrics
    public var options: FormulaDisplayOptions

    public init(
        metrics: FormulaLayoutMetrics = .default,
        options: FormulaDisplayOptions = .default
    ) {
        self.metrics = metrics
        self.options = options
    }

    public func build(
        from rootBox: FormulaLayoutBox,
        rootNode: FormulaDisplayNode
    ) -> FormulaRenderPlan {
        let context = BuildContext(metrics: metrics, options: options)
        let result = buildElements(from: rootBox, offset: .zero, context: context)
        let debugFrames = options.debugFramesEnabled ? collectDebugFrames(from: rootBox, offset: .zero) : []

        var elements = result.elements
        if options.debugFramesEnabled {
            elements.append(contentsOf: debugFrames.map {
                .debugFrame(.init(id: rootBox.id, frame: $0))
            })
        }

        let plan = FormulaRenderPlan(
            size: rootBox.size,
            baseline: rootBox.baseline,
            elements: elements,
            bounds: rootBox.bounds,
            cursorRects: options.cursorVisible ? result.cursorRects : [],
            placeholderRects: result.placeholderRects,
            hitRegions: result.hitRegions,
            debugFrames: debugFrames,
            rootNode: rootNode,
            rootLayoutBox: rootBox
        )

        FormulaDisplayInvariant.validate(plan: plan)
        return plan
    }

    private func buildElements(
        from box: FormulaLayoutBox,
        offset: FormulaPoint,
        context: BuildContext
    ) -> BuildResult {
        let absoluteBounds = box.bounds.offsetBy(dx: offset.x, dy: offset.y)
        var result = BuildResult(
            elements: [],
            cursorRects: box.kind == .cursor ? [absoluteBounds] : [],
            placeholderRects: box.kind == .placeholder ? [absoluteBounds] : [],
            hitRegions: [FormulaHitRegion(id: box.id, frame: absoluteBounds, kind: hitRegionKind(for: box.kind))]
        )

        switch box.kind {
        case .text, .operatorSymbol, .function, .raw, .error:
            let text = box.textContent ?? ""
            if !text.isEmpty {
                result.elements.append(
                    .text(
                        .init(
                            id: box.id,
                            text: text,
                            fontRole: fontRole(for: box),
                            frame: absoluteBounds
                        )
                    )
                )
            }
        case .fraction:
            result.elements.append(
                .line(
                    .init(
                        id: box.id,
                        frame: fractionLineFrame(for: box, absoluteBounds: absoluteBounds, metrics: context.metrics),
                        role: .fractionLine
                    )
                )
            )
        case .sqrt:
            if let radicandChild = box.children.first {
                let radicandOffset = FormulaPoint(
                    x: offset.x + radicandChild.origin.x,
                    y: offset.y + radicandChild.origin.y
                )
                let radicandBounds = radicandChild.box.bounds.offsetBy(dx: radicandOffset.x, dy: radicandOffset.y)
                result.elements.append(
                    .radical(
                        .init(
                            id: box.id,
                            frame: absoluteBounds,
                            overlineStart: .init(x: radicandBounds.minX, y: radicandBounds.minY - context.metrics.sqrtOverlineGap),
                            overlineEnd: .init(x: radicandBounds.maxX, y: radicandBounds.minY - context.metrics.sqrtOverlineGap),
                            role: .radical
                        )
                    )
                )
            }
        case .parentheses:
            result.elements.append(contentsOf: delimiterElements(for: box, absoluteBounds: absoluteBounds, left: "(", right: ")"))
        case .absoluteValue:
            result.elements.append(contentsOf: absoluteValueElements(for: box, absoluteBounds: absoluteBounds, metrics: context.metrics))
        case .cursor:
            if context.options.cursorVisible {
                result.elements.append(.cursor(.init(id: box.id, frame: absoluteBounds)))
            }
        case .placeholder:
            result.elements.append(.placeholder(.init(id: box.id, frame: absoluteBounds)))
        case .sequence, .superscript, .subscript, .scriptPair:
            break
        }

        for child in box.children {
            let childOffset = FormulaPoint(
                x: offset.x + child.origin.x,
                y: offset.y + child.origin.y
            )
            result.merge(buildElements(from: child.box, offset: childOffset, context: context))
        }

        return result
    }

    private func fractionLineFrame(
        for box: FormulaLayoutBox,
        absoluteBounds: FormulaRect,
        metrics: FormulaLayoutMetrics
    ) -> FormulaRect {
        FormulaRect(
            origin: .init(
                x: absoluteBounds.minX,
                y: absoluteBounds.minY + box.baseline - metrics.fractionLineThickness / 2
            ),
            size: .init(
                width: absoluteBounds.size.width,
                height: metrics.fractionLineThickness
            )
        )
    }

    private func delimiterElements(
        for box: FormulaLayoutBox,
        absoluteBounds: FormulaRect,
        left: String,
        right: String
    ) -> [FormulaRenderElement] {
        guard let contentChild = box.children.first else { return [] }
        let leftFrame = FormulaRect(
            origin: absoluteBounds.origin,
            size: .init(width: max(contentChild.origin.x, 1), height: absoluteBounds.size.height)
        )
        let rightFrame = FormulaRect(
            origin: .init(x: absoluteBounds.maxX - leftFrame.size.width, y: absoluteBounds.minY),
            size: leftFrame.size
        )
        return [
            .text(.init(id: box.id, text: left, fontRole: .operatorSymbol, frame: leftFrame)),
            .text(.init(id: box.id, text: right, fontRole: .operatorSymbol, frame: rightFrame))
        ]
    }

    private func absoluteValueElements(
        for box: FormulaLayoutBox,
        absoluteBounds: FormulaRect,
        metrics: FormulaLayoutMetrics
    ) -> [FormulaRenderElement] {
        guard let contentChild = box.children.first else { return [] }
        let strokeWidth = max(metrics.absoluteValueStrokeWidth, 1)
        let leftWidth = max(contentChild.origin.x / 2, strokeWidth)
        let leftFrame = FormulaRect(
            origin: absoluteBounds.origin,
            size: .init(width: leftWidth, height: absoluteBounds.size.height)
        )
        let rightFrame = FormulaRect(
            origin: .init(x: absoluteBounds.maxX - leftWidth, y: absoluteBounds.minY),
            size: .init(width: leftWidth, height: absoluteBounds.size.height)
        )
        return [
            .line(.init(id: box.id, frame: leftFrame, role: .delimiter)),
            .line(.init(id: box.id, frame: rightFrame, role: .delimiter))
        ]
    }

    private func fontRole(for box: FormulaLayoutBox) -> FormulaRenderFontRole {
        switch box.kind {
        case .operatorSymbol:
            return .operatorSymbol
        case .function:
            return .function
        case .raw:
            return .raw
        case .error:
            return .error
        case .text:
            switch box.textRole {
            case .number:
                return .normal
            case .raw:
                return .raw
            case .symbol, .none:
                return .normal
            }
        default:
            return .normal
        }
    }

    private func hitRegionKind(for kind: FormulaLayoutBox.Kind) -> FormulaHitRegionKind {
        switch kind {
        case .cursor:
            return .cursor
        case .placeholder:
            return .placeholder
        case .text, .operatorSymbol, .function, .raw, .error:
            return .text
        case .fraction, .sqrt, .superscript, .subscript, .scriptPair, .parentheses, .absoluteValue:
            return .structure
        case .sequence:
            return .node
        }
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
}

private struct BuildContext {
    var metrics: FormulaLayoutMetrics
    var options: FormulaDisplayOptions
}

private struct BuildResult {
    var elements: [FormulaRenderElement]
    var cursorRects: [FormulaRect]
    var placeholderRects: [FormulaRect]
    var hitRegions: [FormulaHitRegion]

    mutating func merge(_ other: BuildResult) {
        elements.append(contentsOf: other.elements)
        cursorRects.append(contentsOf: other.cursorRects)
        placeholderRects.append(contentsOf: other.placeholderRects)
        hitRegions.append(contentsOf: other.hitRegions)
    }
}
