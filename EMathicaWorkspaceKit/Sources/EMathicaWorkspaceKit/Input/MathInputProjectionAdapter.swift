import EMathicaFormulaDisplayCore
import EMathicaMathInputCore
import Foundation

/// Minimal compatibility adapter that exposes projection-only snapshots to WorkspaceKit
/// without changing the existing editing pipeline.
public enum MathInputProjectionAdapter {
    public static func formulaSnapshot(from editorState: EditorState) -> MathFormula {
        MathFormulaProjection.snapshot(from: editorState.root)
    }

    public static func formulaSnapshot(from state: FormulaInputState) -> MathFormula {
        formulaSnapshot(from: state.editorState)
    }

    public static func displayMarkup(
        from state: FormulaInputState,
        includesInsertionMarkers: Bool = false
    ) -> EMathicaMathInputCore.FormulaDisplayMarkup {
        FormulaDisplayProjection.displayout(
            source: formulaSnapshot(from: state),
            cursor: FormulaDisplayCursorState(editorCursor: state.editorState.cursor),
            includesInsertionMarkers: includesInsertionMarkers
        )
    }

    public static func displayDocument(
        from state: FormulaInputState,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayDocument {
        FormulaDisplayProjection.displayDocument(
            source: formulaSnapshot(from: state),
            cursor: FormulaDisplayCursorState(editorCursor: state.editorState.cursor),
            includesInsertionMarkers: includesInsertionMarkers
        )
    }

    public static func displayProjectionSnapshot(
        from state: FormulaInputState,
        includesInsertionMarkers: Bool = false
    ) -> FormulaDisplayProjectionSnapshot {
        FormulaDisplayProjection.displayProjectionSnapshot(
            source: formulaSnapshot(from: state),
            cursor: FormulaDisplayCursorState(editorCursor: state.editorState.cursor),
            includesInsertionMarkers: includesInsertionMarkers
        )
    }

    public static func latexOutput(from editorState: EditorState) -> String {
        LatexMathRenderer().renderLatex(editorState.root, editing: false)
    }

    public static func latexOutput(from state: FormulaInputState) -> String {
        latexOutput(from: state.editorState)
    }

    @available(*, unavailable, message: "WorkspaceKit must mutate editorState through the existing editor pipeline, not by writing MathFormula back into FormulaInputState.")
    public static func replaceEditorState(
        in state: inout FormulaInputState,
        with formula: MathFormula
    ) {
        fatalError("Unavailable")
    }
}

public extension FormulaInputState {
    var mathFormulaSnapshot: MathFormula {
        MathInputProjectionAdapter.formulaSnapshot(from: self)
    }

    var displayMarkupSnapshot: EMathicaMathInputCore.FormulaDisplayMarkup {
        MathInputProjectionAdapter.displayMarkup(from: self)
    }

    var displayDocumentSnapshot: FormulaDisplayDocument {
        MathInputProjectionAdapter.displayDocument(from: self)
    }

    var displayProjectionSnapshot: FormulaDisplayProjectionSnapshot {
        MathInputProjectionAdapter.displayProjectionSnapshot(from: self)
    }

    func displayDocumentSnapshot(includesInsertionMarkers: Bool) -> FormulaDisplayDocument {
        MathInputProjectionAdapter.displayDocument(
            from: self,
            includesInsertionMarkers: includesInsertionMarkers
        )
    }

    func displayProjectionSnapshot(
        includesInsertionMarkers: Bool
    ) -> FormulaDisplayProjectionSnapshot {
        MathInputProjectionAdapter.displayProjectionSnapshot(
            from: self,
            includesInsertionMarkers: includesInsertionMarkers
        )
    }

    var latexOutputSnapshot: String {
        MathInputProjectionAdapter.latexOutput(from: self)
    }
}
