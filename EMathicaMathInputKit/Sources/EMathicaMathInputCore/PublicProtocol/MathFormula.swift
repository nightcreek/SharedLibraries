import Foundation

/// Immutable structural snapshot projected from the editor layer.
///
/// Projection Freeze Rule:
/// - `MathFormula` is a read-only snapshot.
/// - `MathFormula` must not store cursor, selection, or UI state.
/// - `MathFormula` must not be used as an editing surface.
/// - All mutation remains in `MathNode` + `EditorState` + `MathEditorEngine`.
public indirect enum MathFormula: Hashable {
    case sequence([MathFormula])
    case symbol(String)
    case number(String)
    case operatorSymbol(String)
    case function(MathFunctionFormula)
    case template(MathTemplateFormula)
    case rawLatex(String)
}

public struct MathFunctionFormula: Hashable {
    public let name: String
    public let arguments: [MathFormula]

    public init(name: String, arguments: [MathFormula]) {
        self.name = name
        self.arguments = arguments
    }
}

public struct MathTemplateFormula: Hashable {
    public let kind: MathTemplateKind
    public let fields: [MathFormula]

    public init(kind: MathTemplateKind, fields: [MathFormula]) {
        self.kind = kind
        self.fields = fields
    }
}

public enum MathTemplateKind: String, Hashable {
    case fraction
    case sqrt
    case superscript
    case `subscript`
    case parentheses
    case absoluteValue
}

/// External cursor input for display projection.
///
/// Display Isolation Rule:
/// - display projection may consume cursor state,
/// - but that cursor state stays external to `MathFormula`,
/// - and remains owned by the editor layer.
public struct FormulaDisplayCursorState: Hashable {
    public let editorCursor: EditorCursor

    public init(editorCursor: EditorCursor) {
        self.editorCursor = editorCursor
    }
}

public struct FormulaDisplayMarkup: RawRepresentable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawValue = value
    }
}
