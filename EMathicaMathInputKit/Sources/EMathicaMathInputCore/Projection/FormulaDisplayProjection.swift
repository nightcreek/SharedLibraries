import Foundation

/// Pure display projection from structural math snapshots into markup for a future renderer.
///
/// Display Isolation Rule:
/// - projection is derived-only and must not mutate `MathFormula`,
/// - cursor state is always external input,
/// - display markup must not become editor state.
public enum FormulaDisplayProjection {
    public static func displayout(
        source: MathFormula,
        cursor: FormulaDisplayCursorState? = nil
    ) -> FormulaDisplayMarkup {
        MathInputArchitectureInvariants.validateDisplayProjectionInput(
            source: source,
            cursor: cursor
        )
        _ = cursor
        return FormulaDisplayMarkup(rawValue: serialize(source))
    }

    @available(*, unavailable, message: "displayout must be derived from MathFormula plus external cursor state, not from EditorState.")
    public static func displayout(editorState: EditorState) -> FormulaDisplayMarkup {
        fatalError("Unavailable")
    }

    @available(*, unavailable, message: "displayout must not depend on MathInputSession. Project to MathFormula first, then provide external cursor state.")
    public static func displayout(session: MathInputSession) -> FormulaDisplayMarkup {
        fatalError("Unavailable")
    }

    private static func serialize(_ formula: MathFormula) -> String {
        switch formula {
        case .sequence(let items):
            if items.isEmpty {
                return #"\placeholder{}"#
            }
            return items.map(serialize).joined()
        case .symbol(let value), .number(let value), .operatorSymbol(let value), .rawLatex(let value):
            return value
        case .function(let function):
            let arguments = function.arguments.map(serialize)
            guard let first = arguments.first else {
                return "\\\(function.name)"
            }
            let trailing = arguments.dropFirst().map { "{\($0)}" }.joined()
            return "\\\(function.name){\(first)}\(trailing)"
        case .template(let template):
            return serialize(template)
        }
    }

    private static func serialize(_ template: MathTemplateFormula) -> String {
        switch template.kind {
        case .fraction:
            return #"\frac{\#(field(at: 0, in: template))}{\#(field(at: 1, in: template))}"#
        case .sqrt:
            return #"\sqrt{\#(field(at: 0, in: template))}"#
        case .superscript:
            return "\(field(at: 0, in: template))^{\(field(at: 1, in: template))}"
        case .subscript:
            return "\(field(at: 0, in: template))_{\(field(at: 1, in: template))}"
        case .parentheses:
            return "(\(field(at: 0, in: template)))"
        case .absoluteValue:
            return "|\(field(at: 0, in: template))|"
        }
    }

    private static func field(at index: Int, in template: MathTemplateFormula) -> String {
        guard template.fields.indices.contains(index) else {
            return #"\placeholder{}"#
        }
        return serialize(template.fields[index])
    }
}
