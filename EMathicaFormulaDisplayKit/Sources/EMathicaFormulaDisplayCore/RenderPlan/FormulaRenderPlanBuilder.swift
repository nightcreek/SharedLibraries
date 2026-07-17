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
        var trailingElements: [FormulaRenderElement] = []

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
                let glyphFrame = radicalGlyphFrame(
                    absoluteBounds: absoluteBounds,
                    radicandBounds: radicandBounds,
                    metrics: context.metrics
                )
                let overlineFrame = radicalOverlineFrame(
                    absoluteBounds: absoluteBounds,
                    radicandBounds: radicandBounds,
                    metrics: context.metrics
                )
                trailingElements.append(
                    .text(
                        .init(
                            id: box.id,
                            text: "√",
                            fontRole: .radicalGlyph,
                            frame: glyphFrame
                        )
                    )
                )
                trailingElements.append(
                    .line(
                        .init(
                            id: box.id,
                            frame: overlineFrame,
                            role: .radical
                        )
                    )
                )
            }
        case .parentheses:
            result.elements.append(
                contentsOf: delimiterElements(
                    for: box,
                    absoluteBounds: absoluteBounds,
                    metrics: context.metrics,
                    left: "(",
                    right: ")"
                )
            )
        case .absoluteValue:
            result.elements.append(contentsOf: absoluteValueElements(for: box, absoluteBounds: absoluteBounds, metrics: context.metrics))
        case .piecewise:
            result.elements.append(contentsOf: piecewiseBraceElements(for: box, absoluteBounds: absoluteBounds, metrics: context.metrics))
        case .parametric2D:
            break
        case .cursor:
            if context.options.cursorVisible {
                result.elements.append(.cursor(.init(id: box.id, frame: absoluteBounds)))
            }
        case .insertionMarker:
            break
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

        result.elements.append(contentsOf: trailingElements)

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
        metrics: FormulaLayoutMetrics,
        left: String,
        right: String
    ) -> [FormulaRenderElement] {
        guard let contentChild = box.children.first else { return [] }
        let glyphWidth = max(
            min(contentChild.origin.x * 0.62, metrics.baseFontSize * 0.34),
            metrics.baseFontSize * 0.16
        )
        let leftInset = max((contentChild.origin.x - glyphWidth) * 0.54, 0)
        let leftFrame = FormulaRect(
            origin: .init(x: absoluteBounds.minX + leftInset, y: absoluteBounds.minY),
            size: .init(width: glyphWidth, height: absoluteBounds.size.height)
        )
        let rightFrame = FormulaRect(
            origin: .init(
                x: absoluteBounds.maxX - leftInset - glyphWidth,
                y: absoluteBounds.minY
            ),
            size: .init(width: glyphWidth, height: absoluteBounds.size.height)
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
        let strokeWidth = max(metrics.absoluteValueStrokeWidth, 0.58)
        let leadingInset = max((contentChild.origin.x - strokeWidth) * 0.72, 0)
        let leftFrame = FormulaRect(
            origin: .init(x: absoluteBounds.minX + leadingInset, y: absoluteBounds.minY),
            size: .init(width: strokeWidth, height: absoluteBounds.size.height)
        )
        let rightFrame = FormulaRect(
            origin: .init(x: absoluteBounds.maxX - leadingInset - strokeWidth, y: absoluteBounds.minY),
            size: .init(width: strokeWidth, height: absoluteBounds.size.height)
        )
        return [
            .line(.init(id: box.id, frame: leftFrame, role: .delimiter)),
            .line(.init(id: box.id, frame: rightFrame, role: .delimiter))
        ]
    }

    private func piecewiseBraceElements(
        for box: FormulaLayoutBox,
        absoluteBounds: FormulaRect,
        metrics: FormulaLayoutMetrics
    ) -> [FormulaRenderElement] {
        let strokeWidth = max(metrics.absoluteValueStrokeWidth, 1)
        let braceWidth = max(metrics.baseFontSize * 0.22, metrics.delimiterHorizontalPadding)
        let halfHeight = absoluteBounds.size.height / 2
        let centerY = absoluteBounds.minY + halfHeight
        let leftX = absoluteBounds.minX + strokeWidth / 2

        return [
            .line(
                .init(
                    id: box.id,
                    frame: .init(
                        origin: .init(x: leftX + braceWidth, y: absoluteBounds.minY),
                        size: .init(width: strokeWidth, height: halfHeight - strokeWidth)
                    ),
                    role: .delimiter
                )
            ),
            .line(
                .init(
                    id: box.id,
                    frame: .init(
                        origin: .init(x: leftX + braceWidth, y: centerY + strokeWidth),
                        size: .init(width: strokeWidth, height: max(absoluteBounds.maxY - centerY - strokeWidth, strokeWidth))
                    ),
                    role: .delimiter
                )
            ),
            .line(
                .init(
                    id: box.id,
                    frame: .init(
                        origin: .init(x: leftX, y: centerY - strokeWidth / 2),
                        size: .init(width: braceWidth, height: strokeWidth)
                    ),
                    role: .delimiter
                )
            )
        ]
    }

    private func radicalGlyphFrame(
        absoluteBounds: FormulaRect,
        radicandBounds: FormulaRect,
        metrics: FormulaLayoutMetrics
    ) -> FormulaRect {
        let overlineY = max(absoluteBounds.minY + metrics.fractionLineThickness, radicandBounds.minY - metrics.sqrtOverlineGap)
        let leftBearingPadding = max(metrics.baseFontSize * 0.18, 2)
        let rightPadding = max(metrics.baseFontSize * 0.08, 1)
        let availableWidth = max(radicandBounds.minX - absoluteBounds.minX, metrics.baseFontSize * 0.32)
        let glyphOriginX = absoluteBounds.minX
        let glyphWidth = max(
            min(
                availableWidth - rightPadding,
                max(metrics.baseFontSize * 0.46, leftBearingPadding + metrics.baseFontSize * 0.18)
            ),
            max(metrics.baseFontSize * 0.32, leftBearingPadding + metrics.baseFontSize * 0.12)
        )
        let glyphHeight = max(radicandBounds.size.height + metrics.baseFontSize * 0.42, metrics.baseFontSize * 1.32)
        let glyphTopInset = max(metrics.baseFontSize * 0.04, 0.4)
        let glyphOriginY = max(
            absoluteBounds.minY,
            min(
                overlineY - max(metrics.baseFontSize * 0.18, glyphHeight * 0.12),
                absoluteBounds.maxY - glyphHeight + glyphTopInset
            )
        )
        let glyphHeightWithinBounds = min(glyphHeight, absoluteBounds.maxY - glyphOriginY)
        return FormulaRect(
            origin: .init(x: glyphOriginX, y: glyphOriginY),
            size: .init(width: glyphWidth, height: max(glyphHeightWithinBounds, metrics.baseFontSize))
        )
    }

    private func radicalOverlineFrame(
        absoluteBounds: FormulaRect,
        radicandBounds: FormulaRect,
        metrics: FormulaLayoutMetrics
    ) -> FormulaRect {
        let overlineY = max(absoluteBounds.minY + metrics.fractionLineThickness, radicandBounds.minY - metrics.sqrtOverlineGap)
        let startX = max(
            absoluteBounds.minX,
            radicandBounds.minX - max(metrics.sqrtHorizontalPadding * 0.03, 0.08)
        )
        let endX = max(startX + 2, radicandBounds.maxX + max(metrics.sqrtHorizontalPadding * 0.05, 0.12))
        return FormulaRect(
            origin: .init(x: startX, y: overlineY - metrics.fractionLineThickness / 2),
            size: .init(width: endX - startX, height: metrics.fractionLineThickness)
        )
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
        case .insertionMarker:
            return .cursor
        case .placeholder:
            return .placeholder
        case .text, .operatorSymbol, .function, .raw, .error:
            return .text
        case .fraction, .sqrt, .superscript, .subscript, .scriptPair, .parentheses, .absoluteValue, .parametric2D, .piecewise:
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
