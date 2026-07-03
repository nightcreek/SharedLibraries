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
        let normalized = MathInputCharacterNormalizer.normalize(latex)
        var parser = Parser(input: normalized, latexMode: true)
        return parser.parse()
    }

    public func parseSource(_ source: String) -> MathNode? {
        Self.parseInvocationCount += 1
        let normalized = MathInputCharacterNormalizer.normalize(source)
        var parser = Parser(input: normalized, latexMode: false)
        return parser.parse()
    }
}

private extension SimpleMathParser {
    struct Parser {
        let characters: [Character]
        let latexMode: Bool
        var index: Int = 0

        init(input: String, latexMode: Bool) {
            self.characters = Array(input.trimmingCharacters(in: .whitespacesAndNewlines))
            self.latexMode = latexMode
        }

        mutating func parse() -> MathNode? {
            if characters.isEmpty { return .sequence([]) }
            guard let nodes = parseSequence(until: nil) else { return nil }
            skipWhitespace()
            guard index == characters.count else { return nil }
            return .sequence(nodes)
        }

        private mutating func parseSequence(until terminator: Character?) -> [MathNode]? {
            var nodes: [MathNode] = []

            while index < characters.count {
                skipWhitespace()
                guard index < characters.count else { break }

                let current = characters[index]
                if let terminator, current == terminator {
                    break
                }

                switch current {
                case "\\":
                    guard parseCommand(into: &nodes) else { return nil }
                case "^":
                    advance()
                    guard applyScript(.superscript, into: &nodes) else { return nil }
                case "_":
                    advance()
                    guard applyScript(.subscriptTemplate, into: &nodes) else { return nil }
                case "(":
                    advance()
                    guard let content = parseDelimitedSequence(closingWith: ")") else { return nil }
                    nodes.append(template(.parentheses, [.content: content]))
                case "|":
                    advance()
                    guard let content = parseDelimitedSequence(closingWith: "|") else { return nil }
                    nodes.append(template(.absoluteValue, [.content: content]))
                default:
                    if isOperator(current) {
                        nodes.append(.operatorSymbol(String(current)))
                        advance()
                    } else {
                        nodes.append(.character(String(current)))
                        advance()
                    }
                }
            }

            return nodes
        }

        private mutating func parseCommand(into nodes: inout [MathNode]) -> Bool {
            advance()
            let name = readCommandName()

            switch name {
            case "frac":
                guard let numerator = parseRequiredGroup(),
                      let denominator = parseRequiredGroup() else { return false }
                nodes.append(template(.fraction, [.numerator: numerator, .denominator: denominator]))
                return true
            case "sqrt":
                if match("[") {
                    guard let indexGroup = parseDelimitedSequence(closingWith: "]"),
                          let radicand = parseRequiredGroup() else { return false }
                    nodes.append(template(.nthRoot, [.rootIndex: indexGroup, .radicand: radicand]))
                    return true
                }
                guard let radicand = parseRequiredGroup() else { return false }
                nodes.append(template(.sqrt, [.radicand: radicand]))
                return true
            case "sin", "cos", "tan", "ln", "exp":
                guard let argument = parseFunctionArgument() else { return false }
                nodes.append(template(functionKind(for: name), [.argument: argument]))
                return true
            case "log":
                let base: MathNode
                if match("_") {
                    guard let parsedBase = parseGroupOrAtom() else { return false }
                    base = parsedBase
                } else {
                    base = .sequence([])
                }
                guard let argument = parseFunctionArgument() else { return false }
                nodes.append(template(.log, [.base: base, .argument: argument]))
                return true
            case "left" where match("|"):
                guard let content = parseUntilRightAbsolute() else { return false }
                nodes.append(template(.absoluteValue, [.content: content]))
                return true
            case "right":
                return false
            case "":
                nodes.append(.character("\\"))
                return true
            default:
                return false
            }
        }

        private mutating func applyScript(_ kind: TemplateKind, into nodes: inout [MathNode]) -> Bool {
            guard let base = nodes.popLast() else { return false }
            let operand = parseGroupOrAtom() ?? .sequence([.placeholder])

            switch kind {
            case .superscript:
                nodes.append(
                    template(
                        .superscript,
                        [.base: wrapped(base), .exponent: operand]
                    )
                )
            case .subscriptTemplate:
                nodes.append(
                    template(
                        .subscriptTemplate,
                        [.base: wrapped(base), .subscriptField: operand]
                    )
                )
            default:
                return false
            }
            return true
        }

        private mutating func parseFunctionArgument() -> MathNode? {
            skipWhitespace()
            if match("(") {
                return parseDelimitedSequence(closingWith: ")")
            }
            return parseGroupOrAtom()
        }

        private mutating func parseRequiredGroup() -> MathNode? {
            skipWhitespace()
            guard match("{") else { return nil }
            return parseDelimitedSequence(closingWith: "}")
        }

        private mutating func parseGroupOrAtom() -> MathNode? {
            skipWhitespace()
            guard index < characters.count else { return nil }

            if match("{") {
                return parseDelimitedSequence(closingWith: "}")
            }

            if match("(") {
                guard let content = parseDelimitedSequence(closingWith: ")") else { return nil }
                return template(.parentheses, [.content: content])
            }

            if match("|") {
                guard let content = parseDelimitedSequence(closingWith: "|") else { return nil }
                return template(.absoluteValue, [.content: content])
            }

            if characters[index] == "\\" {
                var single: [MathNode] = []
                guard parseCommand(into: &single), single.count == 1 else { return nil }
                return wrapped(single[0])
            }

            if isOperator(characters[index]) {
                let op = MathNode.operatorSymbol(String(characters[index]))
                advance()
                return .sequence([op])
            }

            let atom = MathNode.character(String(characters[index]))
            advance()
            return .sequence([atom])
        }

        private mutating func parseDelimitedSequence(closingWith terminator: Character) -> MathNode? {
            guard let nodes = parseSequence(until: terminator) else { return nil }
            skipWhitespace()
            guard match(terminator) else { return nil }
            return .sequence(nodes)
        }

        private mutating func parseUntilRightAbsolute() -> MathNode? {
            var nodes: [MathNode] = []

            while index < characters.count {
                if peekCommand("right"), peekNextCharacter(afterCommand: "right") == "|" {
                    advance(count: 1 + "right".count + 1)
                    return .sequence(nodes)
                }

                guard let parsed = parseSequenceElement() else { return nil }
                nodes.append(parsed)
            }

            return nil
        }

        private mutating func parseSequenceElement() -> MathNode? {
            skipWhitespace()
            guard index < characters.count else { return nil }

            let current = characters[index]
            switch current {
            case "\\":
                var nodes: [MathNode] = []
                guard parseCommand(into: &nodes), nodes.count == 1 else { return nil }
                return nodes[0]
            case "^":
                return nil
            case "_":
                return nil
            case "(":
                advance()
                guard let content = parseDelimitedSequence(closingWith: ")") else { return nil }
                return template(.parentheses, [.content: content])
            case "|":
                advance()
                guard let content = parseDelimitedSequence(closingWith: "|") else { return nil }
                return template(.absoluteValue, [.content: content])
            default:
                if isOperator(current) {
                    advance()
                    return .operatorSymbol(String(current))
                }
                advance()
                return .character(String(current))
            }
        }

        private func template(_ kind: TemplateKind, _ fields: [FieldID: MathNode]) -> MathNode {
            let orderedFields = TemplateDefinitionRegistry.definition(for: kind).fields.map { fieldID in
                TemplateField(id: fieldID, node: fields[fieldID] ?? .sequence([.placeholder]))
            }
            return .template(TemplateNode(kind: kind, fields: orderedFields))
        }

        private func wrapped(_ node: MathNode) -> MathNode {
            if case .sequence = node {
                return node
            }
            return .sequence([node])
        }

        private func functionKind(for name: String) -> TemplateKind {
            switch name {
            case "sin": return .sin
            case "cos": return .cos
            case "tan": return .tan
            case "ln": return .ln
            case "exp": return .exp
            default: return .sin
            }
        }

        private func isOperator(_ character: Character) -> Bool {
            ["+", "-", "=", "*", "/", ",", "<", ">"].contains(character)
        }

        private mutating func skipWhitespace() {
            while index < characters.count, characters[index].isWhitespace {
                index += 1
            }
        }

        private mutating func match(_ character: Character) -> Bool {
            guard index < characters.count, characters[index] == character else { return false }
            index += 1
            return true
        }

        private mutating func advance() {
            index += 1
        }

        private mutating func advance(count: Int) {
            index += count
        }

        private mutating func readCommandName() -> String {
            let start = index
            while index < characters.count, characters[index].isLetter {
                index += 1
            }
            return String(characters[start..<index])
        }

        private func peekCommand(_ command: String) -> Bool {
            guard index < characters.count, characters[index] == "\\" else { return false }
            let chars = Array(command)
            guard index + chars.count < characters.count else { return false }
            for (offset, char) in chars.enumerated() {
                if characters[index + 1 + offset] != char {
                    return false
                }
            }
            return true
        }

        private func peekNextCharacter(afterCommand command: String) -> Character? {
            let nextIndex = index + 1 + command.count
            guard nextIndex < characters.count else { return nil }
            return characters[nextIndex]
        }
    }
}
