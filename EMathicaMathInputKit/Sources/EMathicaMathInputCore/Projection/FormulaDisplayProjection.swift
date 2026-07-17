import EMathicaFormulaDisplayCore
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
        FormulaDisplayBridge.markup(source: source, cursor: cursor)
    }

    public static func displayDocument(
        source: MathFormula,
        cursor: FormulaDisplayCursorState? = nil
    ) -> FormulaDisplayDocument {
        FormulaDisplayBridge.document(source: source, cursor: cursor)
    }

    @available(*, unavailable, message: "displayout must be derived from MathFormula plus external cursor state, not from EditorState.")
    public static func displayout(editorState: EditorState) -> FormulaDisplayMarkup {
        fatalError("Unavailable")
    }

    @available(*, unavailable, message: "displayout must not depend on MathInputSession. Project to MathFormula first, then provide external cursor state.")
    public static func displayout(session: MathInputSession) -> FormulaDisplayMarkup {
        fatalError("Unavailable")
    }
}
