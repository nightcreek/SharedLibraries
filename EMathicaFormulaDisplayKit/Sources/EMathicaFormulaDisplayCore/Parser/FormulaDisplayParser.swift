import Foundation

public struct FormulaDisplayParser: Sendable {
    public init() {}

    public func parse(_ markup: FormulaDisplayMarkup) -> FormulaDisplayNode {
        var state = ParserState(input: markup.rawValue)
        return state.parse()
    }
}

private struct ParserState {
    private let characters: [Character]
    private var index: Int = 0

    init(input: String) {
        self.characters = Array(input)
    }

    mutating func parse() -> FormulaDisplayNode {
        wrapSequence(parseSequence(until: nil).nodes)
    }

    private mutating func parseSequence(until terminator: Character?) -> (nodes: [FormulaDisplayNode], closed: Bool) {
        var nodes: [FormulaDisplayNode] = []

        while !isAtEnd {
            if let terminator, peek() == terminator {
                advance()
                return (coalescing(nodes), true)
            }

            if let node = parseNextNode(until: terminator) {
                nodes.append(node)
            }
        }

        return (coalescing(nodes), terminator == nil)
    }

    private mutating func parseNextNode(until terminator: Character?) -> FormulaDisplayNode? {
        guard let current = peek() else { return nil }

        if current == "^" || current == "_" {
            let start = index
            advance()
            return .error(
                .init(
                    kind: .malformedScript,
                    rawText: slice(from: start, to: index)
                )
            )
        }

        let primary = parsePrimary()
        return parseScriptAttachments(for: primary)
    }

    private mutating func parsePrimary() -> FormulaDisplayNode {
        guard let current = peek() else {
            return .sequence([])
        }

        let primary: FormulaDisplayNode
        switch current {
        case "\\":
            primary = parseCommand()
        case "(":
            primary = parseParentheses()
        case "|":
            primary = parseAbsoluteValue()
        case "□":
            advance()
            primary = .placeholder
        default:
            primary = parseTextualPrimary()
        }

        return primary
    }

    private mutating func parseCommand() -> FormulaDisplayNode {
        let start = index
        advance()

        let nameStart = index
        while let current = peek(), isLetter(current) {
            advance()
        }
        let name = slice(from: nameStart, to: index)
        guard !name.isEmpty else {
            return .raw(slice(from: start, to: index))
        }

        switch name {
        case "cursor":
            if consumeExact("{}") {
                return .cursor
            }
            return .error(.init(kind: .unsupportedCommand, rawText: slice(from: start, to: index)))
        case "placeholder":
            if consumeExact("{}") {
                return .placeholder
            }
            return .error(.init(kind: .unsupportedCommand, rawText: slice(from: start, to: index)))
        case "frac":
            let numerator = parseFunctionArgument(wrappingParentheses: false)
            let denominator = parseFunctionArgument(wrappingParentheses: false)
            guard let numerator, let denominator else {
                return .error(.init(kind: .malformedFraction, rawText: slice(from: start, to: index)))
            }
            return .fraction(numerator: numerator, denominator: denominator)
        case "sqrt":
            guard let radicand = parseFunctionArgument(wrappingParentheses: false) else {
                return .error(.init(kind: .unmatchedBrace, rawText: slice(from: start, to: index)))
            }
            return .sqrt(radicand: radicand)
        case "sin", "cos", "tan", "ln":
            guard let argument = parseFunctionArgument(wrappingParentheses: false) else {
                return .error(.init(kind: .unsupportedCommand, rawText: slice(from: start, to: index)))
            }
            return .function(name: name, arguments: [argument])
        case "log":
            guard let first = parseFunctionArgument(wrappingParentheses: false) else {
                return .error(.init(kind: .unsupportedCommand, rawText: slice(from: start, to: index)))
            }
            if let second = parseFunctionArgument(wrappingParentheses: false) {
                return .function(name: name, arguments: [first, second])
            }
            return .function(name: name, arguments: [first])
        default:
            consumeUnknownCommandTail()
            return .error(.init(kind: .unknownCommand, rawText: slice(from: start, to: index)))
        }
    }

    private mutating func parseParentheses() -> FormulaDisplayNode {
        let start = index
        advance()
        let result = parseSequence(until: ")")
        guard result.closed else {
            return .error(.init(kind: .unmatchedDelimiter, rawText: slice(from: start, to: index)))
        }
        return .parentheses(content: wrapSequence(result.nodes))
    }

    private mutating func parseAbsoluteValue() -> FormulaDisplayNode {
        let start = index
        advance()
        let result = parseSequence(until: "|")
        guard result.closed else {
            return .error(.init(kind: .unmatchedDelimiter, rawText: slice(from: start, to: index)))
        }
        return .absoluteValue(content: wrapSequence(result.nodes))
    }

    private mutating func parseTextualPrimary() -> FormulaDisplayNode {
        guard let current = peek() else {
            return .sequence([])
        }

        if isDigit(current) {
            return .text(consumeNumber(), role: .number)
        }

        if isLetter(current) {
            return .text(consumeLetters(), role: .symbol)
        }

        if isOperator(current) {
            advance()
            return .operatorSymbol(String(current))
        }

        let start = index
        advance()
        return .raw(slice(from: start, to: index))
    }

    private mutating func parseScriptAttachments(for base: FormulaDisplayNode) -> FormulaDisplayNode {
        var currentBase = base
        var subscriptNode: FormulaDisplayNode?
        var superscriptNode: FormulaDisplayNode?

        while let current = peek(), current == "^" || current == "_" {
            let operatorStart = index
            let operatorCharacter = advance()
            guard let body = parseScriptBody() else {
                let error = FormulaDisplayNode.error(
                    .init(kind: .malformedScript, rawText: slice(from: operatorStart, to: index))
                )
                return wrapSequence([currentBase, error])
            }

            switch operatorCharacter {
            case "^":
                if superscriptNode != nil {
                    currentBase = foldScript(base: currentBase, subscriptNode: subscriptNode, superscriptNode: superscriptNode)
                    subscriptNode = nil
                }
                superscriptNode = body
            case "_":
                if subscriptNode != nil {
                    currentBase = foldScript(base: currentBase, subscriptNode: subscriptNode, superscriptNode: superscriptNode)
                    superscriptNode = nil
                }
                subscriptNode = body
            default:
                break
            }
        }

        return foldScript(base: currentBase, subscriptNode: subscriptNode, superscriptNode: superscriptNode)
    }

    private mutating func parseScriptBody() -> FormulaDisplayNode? {
        guard !isAtEnd else { return nil }

        if peek() == "{" {
            let start = index
            advance()
            let result = parseSequence(until: "}")
            guard result.closed else {
                return .error(.init(kind: .unmatchedBrace, rawText: slice(from: start, to: index)))
            }
            return wrapSequence(result.nodes)
        }

        return parsePrimary()
    }

    private mutating func parseFunctionArgument(wrappingParentheses: Bool) -> FormulaDisplayNode? {
        guard let current = peek() else { return nil }

        if current == "{" {
            let start = index
            advance()
            let result = parseSequence(until: "}")
            guard result.closed else {
                let rawText = slice(from: start, to: index)
                return .error(.init(kind: .unmatchedBrace, rawText: rawText))
            }
            return wrapSequence(result.nodes)
        }

        if current == "(" {
            let start = index
            advance()
            let result = parseSequence(until: ")")
            guard result.closed else {
                let rawText = slice(from: start, to: index)
                return .error(.init(kind: .unmatchedDelimiter, rawText: rawText))
            }
            let content = wrapSequence(result.nodes)
            return wrappingParentheses ? .parentheses(content: content) : content
        }

        return nil
    }

    private mutating func consumeUnknownCommandTail() {
        while let current = peek(), current == "{" || current == "(" {
            if !consumeBalancedSegment(startingWith: current) {
                break
            }
        }
    }

    private mutating func consumeBalancedSegment(startingWith opener: Character) -> Bool {
        let closer: Character
        switch opener {
        case "{": closer = "}"
        case "(": closer = ")"
        default: return false
        }

        guard peek() == opener else { return false }
        advance()
        var depth = 1

        while !isAtEnd, let current = peek() {
            advance()
            if current == opener {
                depth += 1
            } else if current == closer {
                depth -= 1
                if depth == 0 {
                    return true
                }
            }
        }
        return false
    }

    private func foldScript(
        base: FormulaDisplayNode,
        subscriptNode: FormulaDisplayNode?,
        superscriptNode: FormulaDisplayNode?
    ) -> FormulaDisplayNode {
        switch (subscriptNode, superscriptNode) {
        case let (sub?, sup?):
            return .scriptPair(base: base, subscriptNode: sub, superscriptNode: sup)
        case let (sub?, nil):
            return .subscript(base: base, subscriptNode: sub)
        case let (nil, sup?):
            return .superscript(base: base, exponent: sup)
        case (nil, nil):
            return base
        }
    }

    private func wrapSequence(_ nodes: [FormulaDisplayNode]) -> FormulaDisplayNode {
        let flattened = coalescing(nodes)
        if flattened.count == 1, let single = flattened.first {
            return single
        }
        return .sequence(flattened)
    }

    private func coalescing(_ nodes: [FormulaDisplayNode]) -> [FormulaDisplayNode] {
        var result: [FormulaDisplayNode] = []

        func appendText(_ value: String, role: FormulaTextRole) {
            if case .text(let previous, let previousRole)? = result.last, previousRole == role {
                result[result.count - 1] = .text(previous + value, role: role)
            } else {
                result.append(.text(value, role: role))
            }
        }

        for node in nodes {
            switch node {
            case .sequence(let nested):
                for nestedNode in nested {
                    switch nestedNode {
                    case .text(let value, let role):
                        appendText(value, role: role)
                    default:
                        result.append(nestedNode)
                    }
                }
            case .text(let value, let role):
                appendText(value, role: role)
            default:
                result.append(node)
            }
        }

        return result
    }

    private mutating func consumeLetters() -> String {
        let start = index
        while let current = peek(), isLetter(current) {
            advance()
        }
        return slice(from: start, to: index)
    }

    private mutating func consumeNumber() -> String {
        let start = index
        var seenDot = false

        while let current = peek() {
            if isDigit(current) {
                advance()
            } else if current == ".", !seenDot {
                seenDot = true
                advance()
            } else {
                break
            }
        }

        return slice(from: start, to: index)
    }

    private mutating func consumeExact(_ exact: String) -> Bool {
        let expected = Array(exact)
        guard characters.dropFirst(index).starts(with: expected) else {
            return false
        }
        index += expected.count
        return true
    }

    private func isLetter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }

    private func isDigit(_ character: Character) -> Bool {
        character.isNumber
    }

    private func isOperator(_ character: Character) -> Bool {
        "+-=*/,.:;<>".contains(character)
    }

    private var isAtEnd: Bool {
        index >= characters.count
    }

    private func peek() -> Character? {
        guard index < characters.count else { return nil }
        return characters[index]
    }

    @discardableResult
    private mutating func advance() -> Character {
        let character = characters[index]
        index += 1
        return character
    }

    private func slice(from start: Int, to end: Int) -> String {
        guard start < end else { return "" }
        return String(characters[start..<end])
    }
}
