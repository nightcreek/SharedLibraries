import EMathicaMathCore
import Foundation

public struct ParameterSuggestionAnalysis: Hashable, Sendable {
    public struct Suggestion: Hashable, Identifiable, Sendable {
        public var id: String { symbol }
        var symbol: String
        var restriction: String?
    }

    public var suggestions: [Suggestion]
    public var restrictions: [String]
    public var preview: String

    public static let empty = ParameterSuggestionAnalysis(suggestions: [], restrictions: [], preview: "")
}

public enum ParameterSuggestionAnalyzer {
    public static func analyze(_ input: String, existingObjects: [MathObject]) -> ParameterSuggestionAnalysis {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }

        let existingNames = Set(existingObjects.map(\.name))
        let known = existingNames.union([
            "x", "y", "z", "t", "u", "v",
            "pi", "π", "e",
            "sin", "cos", "tan", "sqrt", "abs", "ln", "log", "exp"
        ])

        let symbols = Set(symbols(in: trimmed))
        let suggestions = symbols
            .filter { !known.contains($0) }
            .sorted()
            .map { symbol in
                ParameterSuggestionAnalysis.Suggestion(
                    symbol: symbol,
                    restriction: suggestedRestriction(for: symbol, input: trimmed)
                )
            }

        return ParameterSuggestionAnalysis(
            suggestions: suggestions,
            restrictions: suggestions.compactMap(\.restriction),
            preview: trimmed
        )
    }

    private static func symbols(in input: String) -> [String] {
        let pattern = #"[A-Za-zπ]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(input.startIndex..<input.endIndex, in: input)
        return regex.matches(in: input, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: input) else { return nil }
            let token = String(input[range])
            return normalizedSymbol(token)
        }
    }

    private static func normalizedSymbol(_ token: String) -> String? {
        if token == "π" { return token }
        let lower = token.lowercased()
        if ["sin", "cos", "tan", "sqrt", "abs", "ln", "log", "exp"].contains(lower) {
            return lower
        }
        if lower.count == 1 || lower == "pi" {
            return lower
        }
        return nil
    }

    private static func suggestedRestriction(for symbol: String, input: String) -> String? {
        if symbol == "n" {
            return "n > 0"
        }
        if input.contains("/\(symbol)") || input.contains("\\frac") {
            return "\(symbol) ≠ 0"
        }
        if symbol == "r" {
            return "r ≥ 0"
        }
        return nil
    }
}
