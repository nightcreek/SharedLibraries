import Foundation

final class AlgebraLatexParser {
    private let tokens: [AlgebraToken]
    private var index: Int = 0
    private var diagnostics: [AlgebraDiagnostic] = []

    nonisolated init(_ input: String) {
        self.tokens = AlgebraLatexLexer(input).tokenize()
    }

    nonisolated func parse() -> AlgebraParseResult {
        let left = parseExpression()
        if match(.equal) {
            let right = parseExpression()
            return AlgebraParseResult(
                relation: .equation(AlgebraEquation(left: left, right: right)),
                diagnostics: diagnostics
            )
        }
        return AlgebraParseResult(relation: .expression(left), diagnostics: diagnostics)
    }

    nonisolated private func parseExpression(stopsAtVerticalBar: Bool = false) -> AlgebraExpression {
        var expression = parseTerm(stopsAtVerticalBar: stopsAtVerticalBar)
        while true {
            if stopsAtVerticalBar, peek() == .verticalBar {
                return expression
            }
            if match(.plus) {
                expression = .add([expression, parseTerm(stopsAtVerticalBar: stopsAtVerticalBar)])
            } else if match(.minus) {
                expression = .add([expression, .multiply([.number(-1), parseTerm(stopsAtVerticalBar: stopsAtVerticalBar)])])
            } else {
                return expression
            }
        }
    }

    nonisolated private func parseTerm(stopsAtVerticalBar: Bool = false) -> AlgebraExpression {
        var expression = parsePower(stopsAtVerticalBar: stopsAtVerticalBar)
        while true {
            if stopsAtVerticalBar, peek() == .verticalBar {
                return expression
            }
            if match(.star) {
                expression = .multiply([expression, parsePower(stopsAtVerticalBar: stopsAtVerticalBar)])
            } else if match(.slash) {
                expression = .divide(expression, parsePower(stopsAtVerticalBar: stopsAtVerticalBar))
            } else if beginsPrimary(peek()) {
                expression = .multiply([expression, parsePower(stopsAtVerticalBar: stopsAtVerticalBar)])
            } else {
                return expression
            }
        }
    }

    nonisolated private func parsePower(stopsAtVerticalBar: Bool = false) -> AlgebraExpression {
        var base = parsePrimary(stopsAtVerticalBar: stopsAtVerticalBar)
        while match(.caret) {
            base = .power(base, parsePrimary(stopsAtVerticalBar: stopsAtVerticalBar))
        }
        return base
    }

    nonisolated private func parsePrimary(stopsAtVerticalBar: Bool = false) -> AlgebraExpression {
        if match(.minus) {
            return .multiply([.number(-1), parsePrimary(stopsAtVerticalBar: stopsAtVerticalBar)])
        }

        let token = advance()
        switch token {
        case .number(let value):
            return .number(value)
        case .identifier(let name):
            if isFunction(name), beginsPrimary(peek()) {
                return .function(name, parsePrimary(stopsAtVerticalBar: stopsAtVerticalBar))
            }
            if let argument = parseUserFunctionArgument(for: name) {
                return .function(name, argument)
            }
            return .symbol(name)
        case .command("frac"):
            let numerator = parseRequiredGroup(commandName: "frac")
            let denominator = parseRequiredGroup(commandName: "frac")
            return .divide(numerator, denominator)
        case .command("sqrt"):
            if match(.leftBracket) {
                let degree = parseExpression()
                consume(.rightBracket)
                let radicand = parseRequiredGroup(commandName: "sqrt")
                return .power(radicand, .divide(.number(1), degree))
            }
            return .power(parseRequiredGroup(commandName: "sqrt"), .number(0.5))
        case .command(let name) where isFunction(name):
            if match(.caret) {
                let exponent = parsePrimary(stopsAtVerticalBar: stopsAtVerticalBar)
                let argument = beginsPrimary(peek()) ? parsePrimary(stopsAtVerticalBar: stopsAtVerticalBar) : .symbol("x")
                return .power(.function(name, argument), exponent)
            }
            let argument = beginsPrimary(peek()) ? parsePrimary(stopsAtVerticalBar: stopsAtVerticalBar) : .symbol("x")
            return .function(name, argument)
        case .command("pi"):
            return .symbol("pi")
        case .verticalBar:
            let expression = parseExpression(stopsAtVerticalBar: true)
            consume(.verticalBar)
            return .function("abs", expression)
        case .leftParen, .leftBrace:
            let expression = parseExpression()
            _ = match(.rightParen) || match(.rightBrace)
            return expression
        case .end:
            diagnostics.append(AlgebraDiagnostic(severity: .error, message: "表达式不完整"))
            return .number(0)
        default:
            diagnostics.append(AlgebraDiagnostic(severity: .warning, message: "暂不支持的 LaTeX 片段"))
            return .number(0)
        }
    }

    nonisolated private func parseRequiredGroup(commandName: String) -> AlgebraExpression {
        guard match(.leftBrace) else {
            diagnostics.append(AlgebraDiagnostic(severity: .error, message: "\\\(commandName) 缺少花括号参数"))
            return .number(0)
        }
        let expression = parseExpression()
        consume(.rightBrace)
        return expression
    }

    nonisolated private func parseUserFunctionArgument(for name: String) -> AlgebraExpression? {
        guard !["x", "y", "z", "pi", "e"].contains(name) else { return nil }

        if match(.leftParen) {
            let expression = parseExpression()
            consume(.rightParen)
            return expression
        }
        if match(.leftBrace) {
            let expression = parseExpression()
            consume(.rightBrace)
            return expression
        }
        return nil
    }

    nonisolated private func beginsPrimary(_ token: AlgebraToken) -> Bool {
        switch token {
        case .number, .identifier, .command, .leftParen, .leftBrace, .verticalBar:
            return true
        default:
            return false
        }
    }

    nonisolated private func isFunction(_ name: String) -> Bool {
        ["sin", "cos", "tan", "sqrt", "abs", "log", "ln", "exp"].contains(name)
    }

    nonisolated private func peek() -> AlgebraToken {
        tokens[min(index, tokens.count - 1)]
    }

    nonisolated private func advance() -> AlgebraToken {
        let token = peek()
        index = min(index + 1, tokens.count)
        return token
    }

    nonisolated private func match(_ expected: AlgebraToken) -> Bool {
        guard peek() == expected else { return false }
        _ = advance()
        return true
    }

    nonisolated private func consume(_ expected: AlgebraToken) {
        if !match(expected) {
            diagnostics.append(AlgebraDiagnostic(severity: .warning, message: "表达式括号未闭合"))
        }
    }
}
