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
        return FormulaDisplayMarkup(
            rawValue: serialize(
                source,
                path: [],
                cursor: cursor?.editorCursor
            )
        )
    }

    @available(*, unavailable, message: "displayout must be derived from MathFormula plus external cursor state, not from EditorState.")
    public static func displayout(editorState: EditorState) -> FormulaDisplayMarkup {
        fatalError("Unavailable")
    }

    @available(*, unavailable, message: "displayout must not depend on MathInputSession. Project to MathFormula first, then provide external cursor state.")
    public static func displayout(session: MathInputSession) -> FormulaDisplayMarkup {
        fatalError("Unavailable")
    }

    private static let cursorMarker = #"\cursor{}"#
    private static let placeholderMarker = #"\placeholder{}"#

    private static func serialize(
        _ formula: MathFormula,
        path: [EditorPathComponent],
        cursor: EditorCursor?
    ) -> String {
        switch formula {
        case .sequence(let items):
            return serializeSequence(items, path: path, cursor: cursor)
        case .symbol(let value), .number(let value), .operatorSymbol(let value), .rawLatex(let value):
            return value
        case .function(let function):
            let arguments = function.arguments.enumerated().map { index, argument in
                let fieldPath = path + [.templateField(functionFieldID(for: function, argumentIndex: index))]
                return serialize(argument, path: fieldPath, cursor: cursor)
            }
            guard let first = arguments.first else {
                return "\\\(function.name)"
            }
            let trailing = arguments.dropFirst().map { "{\($0)}" }.joined()
            return "\\\(function.name){\(first)}\(trailing)"
        case .template(let template):
            return serialize(template, path: path, cursor: cursor)
        }
    }

    private static func serializeSequence(
        _ items: [MathFormula],
        path: [EditorPathComponent],
        cursor: EditorCursor?
    ) -> String {
        if items.isEmpty {
            let cursorPrefix = cursorMarkerIfNeeded(path: path, offset: 0, cursor: cursor)
            return cursorPrefix + placeholderMarker
        }

        var output = cursorMarkerIfNeeded(path: path, offset: 0, cursor: cursor)
        for (index, item) in items.enumerated() {
            output += serialize(
                item,
                path: path + [.sequenceIndex(index)],
                cursor: cursor
            )
            output += cursorMarkerIfNeeded(path: path, offset: index + 1, cursor: cursor)
        }
        return output
    }

    private static func serialize(
        _ template: MathTemplateFormula,
        path: [EditorPathComponent],
        cursor: EditorCursor?
    ) -> String {
        switch template.kind {
        case .fraction:
            return #"\frac{\#(field(.numerator, at: 0, in: template, path: path, cursor: cursor))}{\#(field(.denominator, at: 1, in: template, path: path, cursor: cursor))}"#
        case .sqrt:
            return #"\sqrt{\#(field(.radicand, at: 0, in: template, path: path, cursor: cursor))}"#
        case .superscript:
            return "\(field(.base, at: 0, in: template, path: path, cursor: cursor))^{\(field(.exponent, at: 1, in: template, path: path, cursor: cursor))}"
        case .subscript:
            return "\(field(.base, at: 0, in: template, path: path, cursor: cursor))_{\(field(.subscriptField, at: 1, in: template, path: path, cursor: cursor))}"
        case .parentheses:
            return "(\(field(.content, at: 0, in: template, path: path, cursor: cursor)))"
        case .absoluteValue:
            return "|\(field(.content, at: 0, in: template, path: path, cursor: cursor))|"
        case .piecewise2:
            return #"\piecewise{\#(field(.rowExpression(0), at: 0, in: template, path: path, cursor: cursor))}{\#(field(.rowCondition(0), at: 1, in: template, path: path, cursor: cursor))}{\#(field(.rowExpression(1), at: 2, in: template, path: path, cursor: cursor))}{\#(field(.rowCondition(1), at: 3, in: template, path: path, cursor: cursor))}"#
        case .parametric2D:
            return #"\parametric{\#(field(.parametricExpression(0), at: 0, in: template, path: path, cursor: cursor))}{\#(field(.parametricExpression(1), at: 1, in: template, path: path, cursor: cursor))}{\#(field(.parametricRange, at: 2, in: template, path: path, cursor: cursor))}"#
        }
    }

    private static func field(
        _ id: FieldID,
        at index: Int,
        in template: MathTemplateFormula,
        path: [EditorPathComponent],
        cursor: EditorCursor?
    ) -> String {
        let fieldPath = path + [.templateField(id)]
        guard template.fields.indices.contains(index) else {
            return serialize(.sequence([]), path: fieldPath, cursor: cursor)
        }
        return serialize(template.fields[index], path: fieldPath, cursor: cursor)
    }

    private static func cursorMarkerIfNeeded(
        path: [EditorPathComponent],
        offset: Int,
        cursor: EditorCursor?
    ) -> String {
        guard let cursor, cursor.path == path, cursor.offset == offset else {
            return ""
        }
        return cursorMarker
    }

    private static func functionFieldID(
        for function: MathFunctionFormula,
        argumentIndex: Int
    ) -> FieldID {
        if function.name == "log", function.arguments.count > 1 {
            return argumentIndex == 0 ? .base : .argument
        }
        return .argument
    }
}
