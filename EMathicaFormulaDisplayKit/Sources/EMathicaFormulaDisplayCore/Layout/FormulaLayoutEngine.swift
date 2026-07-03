import Foundation

public struct FormulaLayoutEngine: Sendable {
    public var metrics: FormulaLayoutMetrics

    public init(metrics: FormulaLayoutMetrics = .default) {
        self.metrics = metrics
    }

    public func layout(_ node: FormulaDisplayNode) -> FormulaLayoutBox {
        layout(node, metrics: metrics, path: "root")
    }

    private func layout(
        _ node: FormulaDisplayNode,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        switch node {
        case .sequence(let items):
            return layoutSequence(items, metrics: metrics, path: path)
        case .text(let value, let role):
            return layoutText(value, kind: .text, textRole: role, metrics: metrics, path: path)
        case .operatorSymbol(let value):
            return layoutText(value, kind: .operatorSymbol, metrics: metrics, path: path)
        case .function(let name, let arguments):
            return layoutFunction(name: name, arguments: arguments, metrics: metrics, path: path)
        case .fraction(let numerator, let denominator):
            return layoutFraction(numerator: numerator, denominator: denominator, metrics: metrics, path: path)
        case .sqrt(let radicand):
            return layoutSqrt(radicand: radicand, metrics: metrics, path: path)
        case .superscript(let base, let exponent):
            return layoutSuperscript(base: base, exponent: exponent, metrics: metrics, path: path)
        case .subscript(let base, let subscriptNode):
            return layoutSubscript(base: base, subscriptNode: subscriptNode, metrics: metrics, path: path)
        case .scriptPair(let base, let subscriptNode, let superscriptNode):
            return layoutScriptPair(
                base: base,
                subscriptNode: subscriptNode,
                superscriptNode: superscriptNode,
                metrics: metrics,
                path: path
            )
        case .parentheses(let content):
            return layoutDelimited(content: content, kind: .parentheses, metrics: metrics, path: path)
        case .absoluteValue(let content):
            return layoutDelimited(content: content, kind: .absoluteValue, metrics: metrics, path: path)
        case .cursor:
            return layoutCursor(metrics: metrics, path: path)
        case .placeholder:
            return layoutPlaceholder(metrics: metrics, path: path)
        case .raw(let value):
            return layoutText(
                value,
                kind: .raw,
                textRole: .raw,
                metrics: metrics,
                path: path,
                horizontalPadding: metrics.rawFallbackPadding
            )
        case .error(let error):
            return layoutText(
                error.rawText,
                kind: .error,
                textRole: .raw,
                metrics: metrics,
                path: path,
                horizontalPadding: metrics.rawFallbackPadding
            )
        }
    }

    private func layoutSequence(
        _ items: [FormulaDisplayNode],
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        if items.isEmpty {
            let height = max(metrics.minimumBoxSize.height, metrics.baseFontSize * 1.2)
            let baseline = max(0, min(height, metrics.baseFontSize * 0.8))
            let size = FormulaSize(width: max(0, metrics.minimumBoxSize.width * 0.5), height: height)
            return makeBox(
                id: path,
                kind: .sequence,
                size: size,
                baseline: baseline,
                children: [],
                bounds: .init(origin: .zero, size: size)
            )
        }

        let childBoxes = items.enumerated().map {
            layout($0.element, metrics: metrics, path: "\(path).s\($0.offset)")
        }
        let baseline = childBoxes.map(\.baseline).max()
            ?? max(metrics.baseFontSize * 0.8, metrics.minimumBoxSize.height * 0.5)

        var positioned: [FormulaLayoutChild] = []
        var x = 0.0
        var maxBottom = 0.0

        for (index, child) in childBoxes.enumerated() {
            let y = baseline - child.baseline
            positioned.append(.init(box: child, origin: .init(x: x, y: y)))
            maxBottom = max(maxBottom, y + child.size.height)

            x += child.size.width
            if index < items.count - 1 {
                x += spacing(
                    between: items[index],
                    and: items[index + 1],
                    metrics: metrics
                )
            }
        }

        let size = FormulaSize(
            width: max(x, metrics.minimumBoxSize.width * 0.5),
            height: max(maxBottom, metrics.minimumBoxSize.height)
        )
        return makeBox(
            id: path,
            kind: .sequence,
            size: size,
            baseline: baseline,
            children: positioned,
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutText(
        _ value: String,
        kind: FormulaLayoutBox.Kind,
        textRole: FormulaTextRole? = nil,
        metrics: FormulaLayoutMetrics,
        path: String,
        horizontalPadding: Double = 0
    ) -> FormulaLayoutBox {
        let characterWidth = max(metrics.baseFontSize * 0.6, 1)
        let height = max(metrics.minimumBoxSize.height, metrics.baseFontSize * 1.2)
        let width = max(
            metrics.minimumBoxSize.width,
            Double(max(value.count, 1)) * characterWidth + horizontalPadding * 2
        )
        let size = FormulaSize(width: width, height: height)
        return makeBox(
            id: path,
            kind: kind,
            size: size,
            baseline: min(height, metrics.baseFontSize * 0.8),
            children: [],
            bounds: .init(origin: .zero, size: size),
            textContent: value,
            textRole: textRole
        )
    }

    private func layoutFunction(
        name: String,
        arguments: [FormulaDisplayNode],
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let nameBox = layoutText(name, kind: .function, metrics: metrics, path: "\(path).name")
        let argumentBoxes = arguments.enumerated().map {
            layout($0.element, metrics: metrics, path: "\(path).arg\($0.offset)")
        }

        let baseline = max(nameBox.baseline, argumentBoxes.map(\.baseline).max() ?? 0)
        var children: [FormulaLayoutChild] = []
        var x = 0.0
        children.append(.init(box: nameBox, origin: .init(x: x, y: baseline - nameBox.baseline)))
        x += nameBox.size.width

        for (index, box) in argumentBoxes.enumerated() {
            x += metrics.functionSpacing
            children.append(.init(box: box, origin: .init(x: x, y: baseline - box.baseline)))
            x += box.size.width
            if index < argumentBoxes.count - 1 {
                x += metrics.functionSpacing
            }
        }

        let height = children.map { $0.origin.y + $0.box.size.height }.max() ?? nameBox.size.height
        let size = FormulaSize(width: max(x, nameBox.size.width), height: max(height, metrics.minimumBoxSize.height))
        return makeBox(
            id: path,
            kind: .function,
            size: size,
            baseline: baseline,
            children: children,
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutFraction(
        numerator: FormulaDisplayNode,
        denominator: FormulaDisplayNode,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let numeratorBox = layout(numerator, metrics: metrics, path: "\(path).numerator")
        let denominatorBox = layout(denominator, metrics: metrics, path: "\(path).denominator")

        let lineWidth = max(numeratorBox.size.width, denominatorBox.size.width) + metrics.fractionHorizontalPadding * 2
        let lineY = numeratorBox.size.height + metrics.fractionVerticalGap
        let denominatorY = lineY + metrics.fractionLineThickness + metrics.fractionVerticalGap
        let totalHeight = denominatorY + denominatorBox.size.height
        let baseline = numeratorBox.size.height + metrics.fractionVerticalGap + metrics.fractionLineThickness / 2

        let numeratorX = (lineWidth - numeratorBox.size.width) / 2
        let denominatorX = (lineWidth - denominatorBox.size.width) / 2

        let children: [FormulaLayoutChild] = [
            .init(box: numeratorBox, origin: .init(x: numeratorX, y: 0)),
            .init(box: denominatorBox, origin: .init(x: denominatorX, y: denominatorY))
        ]

        let size = FormulaSize(width: max(lineWidth, metrics.minimumBoxSize.width), height: max(totalHeight, metrics.minimumBoxSize.height))
        return makeBox(
            id: path,
            kind: .fraction,
            size: size,
            baseline: baseline,
            children: children,
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutSqrt(
        radicand: FormulaDisplayNode,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let radicandBox = layout(radicand, metrics: metrics, path: "\(path).radicand")
        let radicalWidth = max(metrics.baseFontSize * 0.5, metrics.sqrtHorizontalPadding)
        let topPadding = metrics.sqrtOverlineGap + metrics.fractionLineThickness
        let childOrigin = FormulaPoint(x: radicalWidth + metrics.sqrtHorizontalPadding, y: topPadding)
        let baseline = childOrigin.y + radicandBox.baseline
        let width = childOrigin.x + radicandBox.size.width
        let height = max(childOrigin.y + radicandBox.size.height, metrics.minimumBoxSize.height)

        let size = FormulaSize(width: width, height: height)
        return makeBox(
            id: path,
            kind: .sqrt,
            size: size,
            baseline: baseline,
            children: [.init(box: radicandBox, origin: childOrigin)],
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutSuperscript(
        base: FormulaDisplayNode,
        exponent: FormulaDisplayNode,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let baseBox = layout(base, metrics: metrics, path: "\(path).base")
        let exponentBox = layout(exponent, metrics: metrics.scaledForScript(), path: "\(path).sup")
        return layoutScriptComposite(
            kind: .superscript,
            baseBox: baseBox,
            subscriptBox: nil,
            superscriptBox: exponentBox,
            metrics: metrics,
            path: path
        )
    }

    private func layoutSubscript(
        base: FormulaDisplayNode,
        subscriptNode: FormulaDisplayNode,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let baseBox = layout(base, metrics: metrics, path: "\(path).base")
        let subscriptBox = layout(subscriptNode, metrics: metrics.scaledForScript(), path: "\(path).sub")
        return layoutScriptComposite(
            kind: .subscript,
            baseBox: baseBox,
            subscriptBox: subscriptBox,
            superscriptBox: nil,
            metrics: metrics,
            path: path
        )
    }

    private func layoutScriptPair(
        base: FormulaDisplayNode,
        subscriptNode: FormulaDisplayNode?,
        superscriptNode: FormulaDisplayNode?,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let baseBox = layout(base, metrics: metrics, path: "\(path).base")
        let scriptMetrics = metrics.scaledForScript()
        let subBox = subscriptNode.map { layout($0, metrics: scriptMetrics, path: "\(path).sub") }
        let supBox = superscriptNode.map { layout($0, metrics: scriptMetrics, path: "\(path).sup") }
        return layoutScriptComposite(
            kind: .scriptPair,
            baseBox: baseBox,
            subscriptBox: subBox,
            superscriptBox: supBox,
            metrics: metrics,
            path: path
        )
    }

    private func layoutScriptComposite(
        kind: FormulaLayoutBox.Kind,
        baseBox: FormulaLayoutBox,
        subscriptBox: FormulaLayoutBox?,
        superscriptBox: FormulaLayoutBox?,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let parentBaseline = baseBox.baseline
        let scriptColumnWidth = max(subscriptBox?.size.width ?? 0, superscriptBox?.size.width ?? 0)

        var placements: [(FormulaLayoutBox, FormulaPoint)] = [(baseBox, .zero)]

        if let superscriptBox {
            let y = parentBaseline - metrics.scriptVerticalRaise - superscriptBox.baseline
            placements.append((superscriptBox, .init(x: baseBox.size.width, y: y)))
        }

        if let subscriptBox {
            let y = parentBaseline + metrics.subscriptVerticalDrop - subscriptBox.baseline
            placements.append((subscriptBox, .init(x: baseBox.size.width, y: y)))
        }

        let minY = placements.map(\.1.y).min() ?? 0
        let yShift = min(0, minY) * -1

        let children = placements.map { placement in
            FormulaLayoutChild(
                box: placement.0,
                origin: .init(x: placement.1.x, y: placement.1.y + yShift)
            )
        }

        let height = children.map { $0.origin.y + $0.box.size.height }.max() ?? baseBox.size.height
        let size = FormulaSize(width: baseBox.size.width + scriptColumnWidth, height: max(height, metrics.minimumBoxSize.height))

        return makeBox(
            id: path,
            kind: kind,
            size: size,
            baseline: parentBaseline + yShift,
            children: children,
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutDelimited(
        content: FormulaDisplayNode,
        kind: FormulaLayoutBox.Kind,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let contentBox = layout(content, metrics: metrics, path: "\(path).content")
        let delimiterWidth = max(metrics.baseFontSize * 0.3, metrics.delimiterHorizontalPadding)
        let horizontalInset = delimiterWidth + metrics.delimiterHorizontalPadding
        let childOrigin = FormulaPoint(x: horizontalInset, y: 0)
        let width = contentBox.size.width + horizontalInset * 2
        let height = max(contentBox.size.height, metrics.minimumBoxSize.height)
        let size = FormulaSize(width: width, height: height)

        return makeBox(
            id: path,
            kind: kind,
            size: size,
            baseline: contentBox.baseline + childOrigin.y,
            children: [.init(box: contentBox, origin: childOrigin)],
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutCursor(
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let height = max(metrics.minimumBoxSize.height, metrics.baseFontSize * 1.2)
        let baseline = min(height, metrics.baseFontSize * 0.8)
        let size = FormulaSize(width: max(metrics.cursorWidth, 1), height: height)
        return makeBox(
            id: path,
            kind: .cursor,
            size: size,
            baseline: baseline,
            children: [],
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutPlaceholder(
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let height = max(metrics.placeholderHeight, metrics.minimumBoxSize.height * 0.75)
        let baseline = min(height, height * 0.8)
        let size = FormulaSize(width: max(metrics.placeholderWidth, 1), height: height)
        return makeBox(
            id: path,
            kind: .placeholder,
            size: size,
            baseline: baseline,
            children: [],
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func spacing(
        between left: FormulaDisplayNode,
        and right: FormulaDisplayNode,
        metrics: FormulaLayoutMetrics
    ) -> Double {
        if case .operatorSymbol = left { return metrics.operatorSpacing }
        if case .operatorSymbol = right { return metrics.operatorSpacing }
        if case .function = left { return metrics.functionSpacing }
        return 0
    }

    private func makeBox(
        id: String,
        kind: FormulaLayoutBox.Kind,
        size: FormulaSize,
        baseline: Double,
        children: [FormulaLayoutChild],
        bounds: FormulaRect,
        textContent: String? = nil,
        textRole: FormulaTextRole? = nil
    ) -> FormulaLayoutBox {
        FormulaLayoutBox(
            id: .init(id),
            kind: kind,
            size: size,
            baseline: baseline,
            children: children,
            bounds: bounds,
            textContent: textContent,
            textRole: textRole
        )
    }
}
