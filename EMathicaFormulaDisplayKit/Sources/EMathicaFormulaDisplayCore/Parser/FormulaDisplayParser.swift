import Foundation

/// FR1 skeleton parser.
///
/// FR2 will replace this with a real grammar for the MathInput v1 display
/// subset. The current implementation is intentionally minimal and safe:
/// it preserves raw input and recognizes only the top-level empty/cursor/
/// placeholder cases needed by the initial package skeleton.
public struct FormulaDisplayParser: Sendable {
    public init() {}

    public func parse(_ markup: FormulaDisplayMarkup) -> FormulaDisplayNode {
        let rawValue = markup.rawValue
        if rawValue.isEmpty {
            return .sequence([])
        }
        if rawValue == #"\cursor{}"# {
            return .cursor
        }
        if rawValue == #"\placeholder{}"# || rawValue == "□" {
            return .placeholder
        }
        return .sequence([.text(rawValue)])
    }
}
