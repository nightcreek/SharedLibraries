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

    public static func displayMarkup(from state: FormulaInputState) -> FormulaDisplayMarkup {
        FormulaDisplayProjection.displayout(
            source: formulaSnapshot(from: state),
            cursor: FormulaDisplayCursorState(editorCursor: state.editorState.cursor)
        )
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

    var displayMarkupSnapshot: FormulaDisplayMarkup {
        MathInputProjectionAdapter.displayMarkup(from: self)
    }
}
