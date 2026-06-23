import Foundation

public enum AlgebraToken: Hashable {
    case number(Double)
    case identifier(String)
    case command(String)
    case plus
    case minus
    case star
    case slash
    case caret
    case equal
    case leftParen
    case rightParen
    case leftBrace
    case rightBrace
    case leftBracket
    case rightBracket
    case verticalBar
    case end
}

public struct AlgebraLatexLexer {
    private let characters: [Character]
    private let functionNames = ["sqrt", "sin", "cos", "tan", "log", "ln", "exp", "abs"]

    nonisolated init(_ input: String) {
        self.characters = Array(input.replacingOccurrences(of: "\\left", with: "").replacingOccurrences(of: "\\right", with: ""))
    }

    nonisolated func tokenize() -> [AlgebraToken] {
        var tokens: [AlgebraToken] = []
        var index = 0

        while index < characters.count {
            let ch = characters[index]
            if ch.isWhitespace {
                index += 1
            } else if ch.isNumber || ch == "." {
                let start = index
                index += 1
                while index < characters.count, characters[index].isNumber || characters[index] == "." {
                    index += 1
                }
                let text = String(characters[start..<index])
                tokens.append(.number(Double(text) ?? 0))
            } else if ch.isLetter {
                let start = index
                index += 1
                while index < characters.count, characters[index].isLetter {
                    index += 1
                }
                let text = String(characters[start..<index])
                if text == "pi" || text == "e" {
                    tokens.append(.identifier(text))
                } else if functionNames.contains(text) {
                    tokens.append(.command(text))
                } else if appendFunctionPrefixedTokens(text, to: &tokens) {
                    continue
                } else {
                    for letter in text {
                        tokens.append(.identifier(String(letter)))
                    }
                }
            } else if ch == "\\" {
                index += 1
                let start = index
                while index < characters.count, characters[index].isLetter {
                    index += 1
                }
                tokens.append(.command(String(characters[start..<index])))
            } else {
                switch ch {
                case "+": tokens.append(.plus)
                case "-": tokens.append(.minus)
                case "*", "·": tokens.append(.star)
                case "/": tokens.append(.slash)
                case "^": tokens.append(.caret)
                case "=": tokens.append(.equal)
                case "(": tokens.append(.leftParen)
                case ")": tokens.append(.rightParen)
                case "{": tokens.append(.leftBrace)
                case "}": tokens.append(.rightBrace)
                case "[": tokens.append(.leftBracket)
                case "]": tokens.append(.rightBracket)
                case "|": tokens.append(.verticalBar)
                default: break
                }
                index += 1
            }
        }

        tokens.append(.end)
        return tokens
    }

    nonisolated private func appendFunctionPrefixedTokens(_ text: String, to tokens: inout [AlgebraToken]) -> Bool {
        guard let function = functionNames.first(where: { text.hasPrefix($0) && text.count > $0.count }) else {
            return false
        }

        tokens.append(.command(function))
        let remainder = String(text.dropFirst(function.count))
        if remainder == "pi" || remainder == "e" {
            tokens.append(.identifier(remainder))
        } else {
            for letter in remainder {
                tokens.append(.identifier(String(letter)))
            }
        }
        return true
    }
}
