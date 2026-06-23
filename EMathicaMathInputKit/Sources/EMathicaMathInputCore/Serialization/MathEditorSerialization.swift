import Foundation

public protocol MathRenderer {
    func renderLatex(_ node: MathNode, editing: Bool) -> String
}

public struct LatexMathRenderer: MathRenderer {
    public init() {}
    public func renderLatex(_ node: MathNode, editing: Bool = true) -> String {
        switch node {
        case .sequence(let nodes):
            return nodes.map { renderLatex($0, editing: editing) }.joined()
        case .character(let value), .symbol(let value), .operatorSymbol(let value):
            return value
        case .placeholder:
            return editing ? "\\square" : ""
        case .template(let template):
            return renderTemplate(template, editing: editing)
        }
    }

    private func renderTemplate(_ template: TemplateNode, editing: Bool) -> String {
        func field(_ id: FieldID) -> String {
            renderLatex(template.field(id) ?? .placeholder, editing: editing)
        }
        switch template.kind {
        case .fraction:
            return "\\frac{\(field(.numerator))}{\(field(.denominator))}"
        case .sqrt:
            return "\\sqrt{\(field(.radicand))}"
        case .nthRoot:
            return "\\sqrt[\(field(.rootIndex))]{\(field(.radicand))}"
        case .superscript:
            return "\(scriptBase(field(.base)))^{\(field(.exponent))}"
        case .subscriptTemplate:
            return "\(scriptBase(field(.base)))_{\(field(.subscriptField))}"
        case .subscriptSuperscript:
            return "\(scriptBase(field(.base)))_{\(field(.subscriptField))}^{\(field(.exponent))}"
        case .parentheses:
            return "(\(field(.content)))"
        case .brackets:
            return "[\(field(.content))]"
        case .braces:
            return "\\{\(field(.content))\\}"
        case .absoluteValue:
            return "\\left|\(field(.content))\\right|"
        case .sin:
            return "\\sin(\(field(.argument)))"
        case .cos:
            return "\\cos(\(field(.argument)))"
        case .tan:
            return "\\tan(\(field(.argument)))"
        case .ln:
            return "\\ln(\(field(.argument)))"
        case .exp:
            return "\\exp(\(field(.argument)))"
        case .log:
            let baseNode = template.field(.base) ?? .placeholder
            if baseNode.isEmptyForEditing {
                return "\\log(\(field(.argument)))"
            }
            return "\\log_{\(field(.base))}(\(field(.argument)))"
        case .limit:
            return "\\lim_{\(field(.variable))\\to\(field(.target))} \(field(.expression))"
        case .sum:
            return "\\sum_{\(field(.variable))=\(field(.lowerBound))}^{\(field(.upperBound))} \(field(.expression))"
        case .product:
            return "\\prod_{\(field(.variable))=\(field(.lowerBound))}^{\(field(.upperBound))} \(field(.expression))"
        case .integral:
            return "\\int_{\(field(.lowerBound))}^{\(field(.upperBound))} \(field(.integrand))\\,d\(field(.variable))"
        case .parametricEquation2D:
            let rangeNode = template.field(.parametricRange)
            let hasRange = rangeNode.map { !$0.isEmptyForEditing } ?? false
            if hasRange {
                return "\\left\\{x=\(field(.parametricExpression(0))),\\ y=\(field(.parametricExpression(1)))\\right\\},\\ \(field(.parametricRange))"
            }
            return "\\left\\{x=\(field(.parametricExpression(0))),\\ y=\(field(.parametricExpression(1)))\\right\\}"
        case .parametricEquation3D:
            return "\\begin{cases}x=\(field(.parametricExpression(0)))\\\\y=\(field(.parametricExpression(1)))\\\\z=\(field(.parametricExpression(2)))\\end{cases}"
        case .piecewise(let rows):
            let lines = (0..<rows).map { row in
                "\(field(.rowExpression(row))),&\(field(.rowCondition(row)))"
            }
            return "\\begin{cases}\(lines.joined(separator: "\\\\"))\\end{cases}"
        case .cases(let rows):
            let lines = (0..<rows).map { row in
                field(.rowExpression(row))
            }
            return "\\begin{cases}\(lines.joined(separator: "\\\\"))\\end{cases}"
        case .matrix(let rows, let cols):
            let matrixRows = (0..<rows).map { row in
                (0..<cols).map { col in field(.matrixCell(row: row, col: col)) }.joined(separator: "&")
            }
            return "\\begin{pmatrix}\(matrixRows.joined(separator: "\\\\"))\\end{pmatrix}"
        case .vector, .overline, .hat:
            return field(.content)
        }
    }

    private func scriptBase(_ raw: String) -> String {
        if raw.isEmpty {
            return "\\square"
        }
        if raw.count == 1 {
            return raw
        }
        return "{\(raw)}"
    }
}

public struct SourceSerializer {
    public init() {}
    private let renderer = LatexMathRenderer()

    public func serialize(_ state: EditorState) -> String {
        renderer.renderLatex(state.root, editing: false)
    }

    public func project(_ state: EditorState) -> CursorProjectionResult {
        var output = ""
        var cursorOffset: Int?
        var cursorStops: [CursorStop] = []
        renderSource(
            node: state.root,
            path: [],
            cursor: state.cursor,
            output: &output,
            cursorOffset: &cursorOffset,
            cursorStops: &cursorStops
        )
        return CursorProjectionResult(
            source: output,
            cursorIndex: cursorOffset ?? output.count,
            cursorStops: deduplicatedStops(cursorStops)
        )
    }

    private func renderSource(
        node: MathNode,
        path: [EditorPathComponent],
        cursor: EditorCursor,
        output: inout String,
        cursorOffset: inout Int?,
        cursorStops: inout [CursorStop]
    ) {
        switch node {
        case .sequence(let nodes):
            cursorStops.append(.init(sourceIndex: output.count, cursor: .init(path: path, offset: 0)))
            if cursor.path == path, cursor.offset == 0, cursorOffset == nil {
                cursorOffset = output.count
            }
            for (index, child) in nodes.enumerated() {
                renderSource(
                    node: child,
                    path: path + [.sequenceIndex(index)],
                    cursor: cursor,
                    output: &output,
                    cursorOffset: &cursorOffset,
                    cursorStops: &cursorStops
                )
                cursorStops.append(.init(sourceIndex: output.count, cursor: .init(path: path, offset: index + 1)))
                if cursor.path == path, cursor.offset == index + 1, cursorOffset == nil {
                    cursorOffset = output.count
                }
            }
        case .character(let value), .symbol(let value), .operatorSymbol(let value):
            output.append(value)
        case .placeholder:
            return
        case .template(let template):
            renderTemplate(
                template,
                path: path,
                cursor: cursor,
                output: &output,
                cursorOffset: &cursorOffset,
                cursorStops: &cursorStops
            )
        }
    }

    private func renderTemplate(
        _ template: TemplateNode,
        path: [EditorPathComponent],
        cursor: EditorCursor,
        output: inout String,
        cursorOffset: inout Int?,
        cursorStops: inout [CursorStop]
    ) {
        func field(_ id: FieldID) {
            let fieldPath = path + [.templateField(id)]
            renderSource(
                node: template.field(id) ?? .placeholder,
                path: fieldPath,
                cursor: cursor,
                output: &output,
                cursorOffset: &cursorOffset,
                cursorStops: &cursorStops
            )
        }

        switch template.kind {
        case .fraction:
            output.append("\\frac{")
            field(.numerator)
            output.append("}{")
            field(.denominator)
            output.append("}")
        case .sqrt:
            output.append("\\sqrt{")
            field(.radicand)
            output.append("}")
        case .nthRoot:
            output.append("\\sqrt[")
            field(.rootIndex)
            output.append("]{")
            field(.radicand)
            output.append("}")
        case .superscript:
            field(.base)
            output.append("^{")
            field(.exponent)
            output.append("}")
        case .subscriptTemplate:
            field(.base)
            output.append("_{")
            field(.subscriptField)
            output.append("}")
        case .subscriptSuperscript:
            field(.base)
            output.append("_{")
            field(.subscriptField)
            output.append("}^{")
            field(.exponent)
            output.append("}")
        case .parentheses:
            output.append("(")
            field(.content)
            output.append(")")
        case .brackets:
            output.append("[")
            field(.content)
            output.append("]")
        case .braces:
            output.append("\\{")
            field(.content)
            output.append("\\}")
        case .absoluteValue:
            output.append("\\left|")
            field(.content)
            output.append("\\right|")
        case .sin:
            output.append("\\sin(")
            field(.argument)
            output.append(")")
        case .cos:
            output.append("\\cos(")
            field(.argument)
            output.append(")")
        case .tan:
            output.append("\\tan(")
            field(.argument)
            output.append(")")
        case .ln:
            output.append("\\ln(")
            field(.argument)
            output.append(")")
        case .exp:
            output.append("\\exp(")
            field(.argument)
            output.append(")")
        case .log:
            let baseNode = template.field(.base) ?? .placeholder
            if !baseNode.isEmptyForEditing {
                output.append("\\log_{")
                field(.base)
                output.append("}(")
            } else {
                output.append("\\log(")
            }
            field(.argument)
            output.append(")")
        case .limit:
            output.append("\\lim_{")
            field(.variable)
            output.append("\\to")
            field(.target)
            output.append("} ")
            field(.expression)
        case .sum:
            output.append("\\sum_{")
            field(.variable)
            output.append("=")
            field(.lowerBound)
            output.append("}^{")
            field(.upperBound)
            output.append("} ")
            field(.expression)
        case .product:
            output.append("\\prod_{")
            field(.variable)
            output.append("=")
            field(.lowerBound)
            output.append("}^{")
            field(.upperBound)
            output.append("} ")
            field(.expression)
        case .integral:
            output.append("\\int_{")
            field(.lowerBound)
            output.append("}^{")
            field(.upperBound)
            output.append("} ")
            field(.integrand)
            output.append("\\,d")
            field(.variable)
        case .parametricEquation2D:
            output.append("x={")
            field(.parametricExpression(0))
            output.append("}, y={")
            field(.parametricExpression(1))
            output.append("}")
            let rangeNode = template.field(.parametricRange)
            if rangeNode.map({ !$0.isEmptyForEditing }) ?? false {
                output.append(", ")
                field(.parametricRange)
            }
        case .parametricEquation3D:
            output.append("x={")
            field(.parametricExpression(0))
            output.append("}, y={")
            field(.parametricExpression(1))
            output.append("}, z={")
            field(.parametricExpression(2))
            output.append("}")
        case .piecewise(let rows):
            output.append("piecewise(")
            for row in 0..<rows {
                if row > 0 { output.append(", ") }
                field(.rowExpression(row))
                output.append(" if ")
                field(.rowCondition(row))
            }
            output.append(")")
        case .cases(let rows):
            output.append("cases(")
            for row in 0..<rows {
                if row > 0 { output.append(", ") }
                field(.rowExpression(row))
            }
            output.append(")")
        case .matrix(let rows, let cols):
            output.append("matrix(")
            for row in 0..<rows {
                if row > 0 { output.append(";") }
                for col in 0..<cols {
                    if col > 0 { output.append(",") }
                    field(.matrixCell(row: row, col: col))
                }
            }
            output.append(")")
        case .vector, .overline, .hat:
            field(.content)
        }
    }

    private func deduplicatedStops(_ stops: [CursorStop]) -> [CursorStop] {
        var seen: Set<CursorStop> = []
        var ordered: [CursorStop] = []
        for stop in stops {
            if seen.insert(stop).inserted {
                ordered.append(stop)
            }
        }
        return ordered
    }
}

public struct CursorProjectionResult: Hashable {
    public init(source: String = "", cursorIndex: Int = 0, cursorStops: [CursorStop] = []) { self.source = source; self.cursorIndex = cursorIndex; self.cursorStops = cursorStops }
    public var source: String
    public var cursorIndex: Int
    public var cursorStops: [CursorStop]
}

public struct CursorStop: Hashable {
    public var sourceIndex: Int
    public var cursor: EditorCursor
}

public enum SourceRangeToCursorMapper {
    public static func map(range: Range<Int>, in projection: CursorProjectionResult) -> EditorCursor {
        guard !projection.cursorStops.isEmpty else {
            return EditorCursor(path: [], offset: 0)
        }
        let target = max(0, min(projection.source.count, range.upperBound))
        var best = projection.cursorStops[0]
        var bestDistance = abs(best.sourceIndex - target)
        var bestSpecificity = specificity(best.cursor)
        for stop in projection.cursorStops {
            let d = abs(stop.sourceIndex - target)
            let s = specificity(stop.cursor)
            if d < bestDistance || (d == bestDistance && s > bestSpecificity) {
                bestDistance = d
                best = stop
                bestSpecificity = s
            }
        }
        return best.cursor
    }

    private static func specificity(_ cursor: EditorCursor) -> Int {
        cursor.path.reduce(0) { partial, component in
            switch component {
            case .templateField:
                return partial + 3
            case .sequenceIndex:
                return partial + 1
            }
        }
    }
}

public struct ComputeSerializer {
    public init() {}
    public func serialize(_ state: EditorState) -> String {
        serializeNode(state.root)
    }

    private func serializeNode(_ node: MathNode) -> String {
        switch node {
        case .sequence(let nodes):
            return nodes.map(serializeNode).joined()
        case .character(let value), .symbol(let value), .operatorSymbol(let value):
            return value
        case .placeholder:
            return ""
        case .template(let template):
            return serializeTemplate(template)
        }
    }

    private func serializeTemplate(_ template: TemplateNode) -> String {
        func node(_ id: FieldID) -> String {
            serializeNode(template.field(id) ?? .placeholder)
        }
        switch template.kind {
        case .fraction:
            return "(\(node(.numerator)))/(\(node(.denominator)))"
        case .sqrt:
            return "sqrt(\(node(.radicand)))"
        case .nthRoot:
            return "root(\(node(.rootIndex)),\(node(.radicand)))"
        case .superscript:
            return "(\(node(.base)))^(\(node(.exponent)))"
        case .subscriptTemplate:
            return "\(node(.base))_(\(node(.subscriptField)))"
        case .absoluteValue:
            return "abs(\(node(.content)))"
        case .sin:
            return "sin(\(node(.argument)))"
        case .cos:
            return "cos(\(node(.argument)))"
        case .tan:
            return "tan(\(node(.argument)))"
        case .ln:
            return "ln(\(node(.argument)))"
        case .exp:
            return "exp(\(node(.argument)))"
        case .log:
            let base = node(.base)
            if base.isEmpty {
                return "log(\(node(.argument)))"
            }
            return "log_\(base)(\(node(.argument)))"
        case .parametricEquation2D:
            let rangeNode = template.field(.parametricRange)
            if rangeNode.map({ !$0.isEmptyForEditing }) ?? false {
                return "ParametricCurve(x=\(node(.parametricExpression(0))),y=\(node(.parametricExpression(1))),range=\(node(.parametricRange)))"
            }
            return "ParametricCurve(x=\(node(.parametricExpression(0))),y=\(node(.parametricExpression(1))),parameter=t)"
        case .parametricEquation3D:
            return "ParametricCurve3D(x=\(node(.parametricExpression(0))),y=\(node(.parametricExpression(1))),z=\(node(.parametricExpression(2))),parameter=t)"
        default:
            return SourceSerializer().serialize(EditorState(root: .template(template)))
        }
    }
}

public protocol MathParser {
    func parseLatex(_ latex: String) -> MathNode?
    func parseSource(_ source: String) -> MathNode?
}

public struct SimpleMathParser: MathParser {
    public init() {}
    private(set) static var parseInvocationCount = 0

    public static func resetInvocationCount() {
        parseInvocationCount = 0
    }

    public func parseLatex(_ latex: String) -> MathNode? {
        Self.parseInvocationCount += 1
        return parseSource(latex)
    }

    public func parseSource(_ source: String) -> MathNode? {
        Self.parseInvocationCount += 1
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return .sequence([]) }
        if trimmed == "\\frac{}{}" {
            return .template(TemplateNode(kind: .fraction, fields: [
                .init(id: .numerator, node: .sequence([.placeholder])),
                .init(id: .denominator, node: .sequence([.placeholder]))
            ]))
        }

        let chars = Array(trimmed)
        var nodes: [MathNode] = []
        var index = 0

        while index < chars.count {
            let current = chars[index]
            if current == "^" {
                if let base = nodes.popLast() {
                    let exponentNode: MathNode
                    if index + 1 < chars.count {
                        exponentNode = .sequence([.character(String(chars[index + 1]))])
                        index += 1
                    } else {
                        exponentNode = .sequence([.placeholder])
                    }
                    let superscript = MathNode.template(TemplateNode(kind: .superscript, fields: [
                        .init(id: .base, node: .sequence([base])),
                        .init(id: .exponent, node: exponentNode)
                    ]))
                    nodes.append(superscript)
                } else {
                    nodes.append(.character("^"))
                }
            } else {
                nodes.append(.character(String(current)))
            }
            index += 1
        }

        return .sequence(nodes)
    }
}
