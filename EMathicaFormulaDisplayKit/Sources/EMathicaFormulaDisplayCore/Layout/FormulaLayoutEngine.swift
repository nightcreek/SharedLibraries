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
        case .nthRoot, .brackets, .braces, .accent, .matrix, .cases, .limit, .largeOperator, .integral, .parametric3D:
            return layoutText(
                FormulaDisplayDocumentSerializer.serialize(node),
                kind: .raw,
                textRole: .raw,
                metrics: metrics,
                path: path,
                horizontalPadding: metrics.rawFallbackPadding
            )
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
        case .parametric2D(let x, let y, let range):
            return layoutParametric2D(x: x, y: y, range: range, metrics: metrics, path: path)
        case .piecewise(let rows):
            return layoutPiecewise(rows: rows, metrics: metrics, path: path)
        case .cursor:
            return layoutCursor(metrics: metrics, path: path)
        case .insertionMarker:
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
        let height = max(metrics.minimumBoxSize.height, metrics.baseFontSize * 1.2)
        let width = max(
            metrics.minimumBoxSize.width,
            estimatedTextWidth(
                for: value,
                kind: kind,
                textRole: textRole,
                metrics: metrics
            ) + horizontalPadding * 2
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
        // Reserve enough width for the radical glyph's left bearing so the rendered
        // "√" stays inside the plan bounds instead of being cropped by a tight text frame.
        let radicalWidth = max(metrics.baseFontSize * 0.32, metrics.sqrtHorizontalPadding * 0.72, 5.6)
        let radicalToContentGap = max(metrics.sqrtHorizontalPadding * 0.03, metrics.baseFontSize * 0.008, 0.16)
        let topPadding = max(metrics.sqrtOverlineGap + metrics.fractionLineThickness * 0.28, metrics.baseFontSize * 0.025)
        let childOrigin = FormulaPoint(x: radicalWidth + radicalToContentGap, y: topPadding)
        let baseline = childOrigin.y + radicandBox.baseline
        let width = childOrigin.x + radicandBox.size.width
        let height = max(
            childOrigin.y + radicandBox.size.height,
            radicandBox.size.height + topPadding + metrics.fractionLineThickness,
            metrics.minimumBoxSize.height
        )

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
            let raise = max(metrics.scriptVerticalRaise, superscriptBox.size.height * 0.35)
            let y = parentBaseline - raise - superscriptBox.baseline
            placements.append((superscriptBox, .init(x: baseBox.size.width, y: y)))
        }

        if let subscriptBox {
            let drop = max(metrics.subscriptVerticalDrop, subscriptBox.size.height * 0.3)
            let y = parentBaseline + drop - subscriptBox.baseline
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
        let delimiterWidth: Double
        switch kind {
        case .absoluteValue:
            delimiterWidth = max(metrics.absoluteValueStrokeWidth, 0.58)
        case .parentheses:
            delimiterWidth = max(metrics.baseFontSize * 0.17, metrics.delimiterHorizontalPadding * 0.8, 1.9)
        default:
            delimiterWidth = max(metrics.baseFontSize * 0.2, metrics.delimiterHorizontalPadding * 0.82, 1.9)
        }
        let contentGap = max(
            metrics.delimiterHorizontalPadding * 0.72,
            kind == .absoluteValue ? metrics.baseFontSize * 0.07 : metrics.baseFontSize * 0.085,
            1.35
        )
        let horizontalInset = delimiterWidth + contentGap
        let height = max(
            contentBox.size.height + max(metrics.sqrtOverlineGap, metrics.baseFontSize * 0.08),
            metrics.minimumBoxSize.height
        )
        let childOrigin = FormulaPoint(
            x: horizontalInset,
            y: max(0, (height - contentBox.size.height) / 2)
        )
        let width = contentBox.size.width + horizontalInset * 2
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

    private func layoutParametric2D(
        x: FormulaDisplayNode,
        y: FormulaDisplayNode,
        range: FormulaDisplayNode?,
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let rowMetrics = metrics
        let xLabel = layoutText("x(t)=", kind: .text, textRole: .raw, metrics: rowMetrics, path: "\(path).xlabel")
        let yLabel = layoutText("y(t)=", kind: .text, textRole: .raw, metrics: rowMetrics, path: "\(path).ylabel")
        let xBox = layout(x, metrics: rowMetrics, path: "\(path).x")
        let yBox = layout(y, metrics: rowMetrics, path: "\(path).y")
        let rangeLabel = layoutText("t:", kind: .text, textRole: .raw, metrics: rowMetrics.scaledForScript(), path: "\(path).rangelabel")
        let rangeBox = range.map { layout($0, metrics: rowMetrics.scaledForScript(), path: "\(path).range") }

        let labelWidth = max(xLabel.size.width, yLabel.size.width, rangeLabel.size.width)
        let rowGap = max(metrics.functionSpacing * 0.8, metrics.baseFontSize * 0.14, 2.1)
        let rowOneHeight = max(xLabel.size.height, xBox.size.height)
        let rowTwoHeight = max(yLabel.size.height, yBox.size.height)
        let rowThreeHeight = max(rangeLabel.size.height, rangeBox?.size.height ?? 0)
        let rangePresent = rangeBox != nil && !(rangeBox.map(isVisiblyEmpty) ?? true)

        var children: [FormulaLayoutChild] = []
        let xLabelY = max(0, (rowOneHeight - xLabel.size.height) / 2)
        let xNodeY = max(0, (rowOneHeight - xBox.size.height) / 2)
        children.append(.init(box: xLabel, origin: .init(x: 0, y: xLabelY)))
        children.append(.init(box: xBox, origin: .init(x: labelWidth + metrics.functionSpacing, y: xNodeY)))

        let secondRowY = rowOneHeight + rowGap
        let yLabelY = secondRowY + max(0, (rowTwoHeight - yLabel.size.height) / 2)
        let yNodeY = secondRowY + max(0, (rowTwoHeight - yBox.size.height) / 2)
        children.append(.init(box: yLabel, origin: .init(x: 0, y: yLabelY)))
        children.append(.init(box: yBox, origin: .init(x: labelWidth + metrics.functionSpacing, y: yNodeY)))

        var totalHeight = rowOneHeight + rowGap + rowTwoHeight
        if rangePresent, let rangeBox {
            let thirdRowY = totalHeight + rowGap
            let rangeLabelY = thirdRowY + max(0, (rowThreeHeight - rangeLabel.size.height) / 2)
            let rangeNodeY = thirdRowY + max(0, (rowThreeHeight - rangeBox.size.height) / 2)
            children.append(.init(box: rangeLabel, origin: .init(x: 0, y: rangeLabelY)))
            children.append(.init(box: rangeBox, origin: .init(x: labelWidth + metrics.functionSpacing, y: rangeNodeY)))
            totalHeight = thirdRowY + rowThreeHeight
        }

        let contentWidth = max(xBox.size.width, yBox.size.width, rangeBox?.size.width ?? 0)
        let size = FormulaSize(
            width: max(metrics.minimumBoxSize.width, labelWidth + metrics.functionSpacing + contentWidth),
            height: max(totalHeight, metrics.minimumBoxSize.height)
        )
        let baseline = children
            .filter { $0.box.id.rawValue.hasSuffix(".xlabel") || $0.box.id.rawValue.hasSuffix(".x") }
            .map { $0.origin.y + $0.box.baseline }
            .max() ?? (size.height * 0.45)

        return makeBox(
            id: path,
            kind: .parametric2D,
            size: size,
            baseline: baseline,
            children: children,
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func layoutPiecewise(
        rows: [FormulaPiecewiseRow],
        metrics: FormulaLayoutMetrics,
        path: String
    ) -> FormulaLayoutBox {
        let rowGap = max(metrics.functionSpacing * 0.8, metrics.baseFontSize * 0.14, 2.1)
        let expressionBoxes = rows.enumerated().map {
            layout($0.element.expression, metrics: metrics, path: "\(path).expr\($0.offset)")
        }
        let conditionBoxes = rows.enumerated().map {
            layout($0.element.condition, metrics: metrics, path: "\(path).cond\($0.offset)")
        }
        let expressionWidth = expressionBoxes.map(\.size.width).max() ?? 0
        let conditionWidth = conditionBoxes.map(\.size.width).max() ?? 0
        let braceWidth = max(metrics.baseFontSize * 0.28, metrics.delimiterHorizontalPadding * 1.22)
        let spacing = max(metrics.functionSpacing * 0.82, 1.4)

        var children: [FormulaLayoutChild] = []
        var y = 0.0
        var firstRowBaseline = 0.0

        for index in rows.indices {
            let expr = expressionBoxes[index]
            let cond = conditionBoxes[index]
            let rowHeight = max(expr.size.height, cond.size.height)
            let exprY = y + max(0, (rowHeight - expr.size.height) / 2)
            let condY = y + max(0, (rowHeight - cond.size.height) / 2)
            let exprX = braceWidth + spacing
            let condX = exprX + expressionWidth + spacing
            children.append(.init(box: expr, origin: .init(x: exprX, y: exprY)))
            children.append(.init(box: cond, origin: .init(x: condX, y: condY)))
            if index == 0 {
                firstRowBaseline = exprY + expr.baseline
            }
            y += rowHeight
            if index < rows.count - 1 {
                y += rowGap
            }
        }

        let size = FormulaSize(
            width: max(metrics.minimumBoxSize.width, braceWidth + spacing + expressionWidth + spacing + conditionWidth),
            height: max(y, metrics.minimumBoxSize.height)
        )

        return makeBox(
            id: path,
            kind: .piecewise,
            size: size,
            baseline: firstRowBaseline > 0 ? firstRowBaseline : size.height * 0.35,
            children: children,
            bounds: .init(origin: .zero, size: size)
        )
    }

    private func isVisiblyEmpty(_ box: FormulaLayoutBox) -> Bool {
        if box.kind == .placeholder || box.kind == .cursor {
            return true
        }
        if let textContent = box.textContent {
            return textContent.isEmpty
        }
        return box.children.isEmpty && box.size.width <= 0
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

    private func estimatedTextWidth(
        for value: String,
        kind: FormulaLayoutBox.Kind,
        textRole: FormulaTextRole?,
        metrics: FormulaLayoutMetrics
    ) -> Double {
        let scalarWidth = value.reduce(0.0) { partial, character in
            partial + estimatedCharacterFactor(for: character, kind: kind, textRole: textRole)
        }
        let fallbackFactor = kind == .operatorSymbol ? 0.5 : 0.52
        let widthFactor = max(scalarWidth, fallbackFactor)
        return max(metrics.baseFontSize * widthFactor, 1)
    }

    private func estimatedCharacterFactor(
        for character: Character,
        kind: FormulaLayoutBox.Kind,
        textRole: FormulaTextRole?
    ) -> Double {
        if character.isWhitespace {
            return 0.22
        }

        switch character {
        case "(", ")", "[", "]", "{", "}":
            return 0.28
        case ".", ",", ":", ";", "'", "\"":
            return 0.22
        case "|":
            return 0.2
        case "_":
            return 0.32
        case "=", "+", "-", "×", "÷", "±", "<", ">", "≤", "≥", "≠":
            return kind == .operatorSymbol ? 0.48 : 0.44
        default:
            break
        }

        if character.isNumber {
            return 0.48
        }

        if textRole == .raw {
            switch character {
            case "x", "y", "z", "t", "f", "j", "l", "r":
                return 0.46
            case "m", "w", "M", "W":
                return 0.74
            default:
                break
            }
        }

        if character.isUppercaseASCII {
            return character == "M" || character == "W" ? 0.76 : 0.58
        }

        if character.isLowercaseASCII {
            switch character {
            case "i", "j", "l":
                return 0.3
            case "m", "w":
                return 0.68
            case "f", "r", "t":
                return 0.4
            default:
                return 0.5
            }
        }

        return 0.56
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

private extension Character {
    var isUppercaseASCII: Bool {
        unicodeScalars.count == 1 && unicodeScalars.first?.properties.isUppercase == true
    }

    var isLowercaseASCII: Bool {
        unicodeScalars.count == 1 && unicodeScalars.first?.properties.isLowercase == true
    }
}
