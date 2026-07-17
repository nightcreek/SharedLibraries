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
        cursor: FormulaDisplayCursorState? = nil,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayMarkup {
        FormulaDisplayBridge.markup(
            source: source,
            cursor: cursor,
            includesInsertionMarkers: includesInsertionMarkers
        )
    }

    public static func displayDocument(
        source: MathFormula,
        cursor: FormulaDisplayCursorState? = nil,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayDocument {
        FormulaDisplayBridge.document(
            source: source,
            cursor: cursor,
            includesInsertionMarkers: includesInsertionMarkers
        )
    }

    public static func displayProjectionSnapshot(
        source: MathFormula,
        cursor: FormulaDisplayCursorState? = nil,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayProjectionSnapshot {
        FormulaDisplayBridge.projectionSnapshot(
            source: source,
            cursor: cursor,
            includesInsertionMarkers: includesInsertionMarkers
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
}
