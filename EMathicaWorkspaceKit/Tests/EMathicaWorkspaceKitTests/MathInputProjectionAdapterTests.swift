import XCTest
@testable import EMathicaWorkspaceKit
import EMathicaMathInputCore

final class MathInputProjectionAdapterTests: XCTestCase {
    func testFormulaInputStateExposesProjectionSnapshot() {
        var state = FormulaInputState()
        state.editorState.root = .sequence([
            .character("x"),
            .operatorSymbol("+"),
            .character("1")
        ])

        XCTAssertEqual(
            state.mathFormulaSnapshot,
            .sequence([
                .symbol("x"),
                .operatorSymbol("+"),
                .number("1")
            ])
        )
    }

    func testDisplayMarkupSnapshotUsesProjectionAdapterWithoutChangingEditorState() {
        let root: MathNode = .template(
            TemplateNode(
                kind: .fraction,
                fields: [
                    TemplateField(id: .numerator, node: .sequence([.character("x")])),
                    TemplateField(id: .denominator, node: .sequence([]))
                ]
            )
        )

        let editorState = EditorState(
            root: .sequence([root]),
            cursor: EditorCursor(path: [], offset: 1),
            selection: nil
        )
        let state = FormulaInputState(editorState: editorState)

        let before = state.editorState
        let markup = state.displayMarkupSnapshot

        XCTAssertEqual(state.editorState, before)
        XCTAssertEqual(markup.rawValue, #"\frac{x}{\placeholder{}}"#)
    }

    func testProjectionAdapterReadsStableSnapshotsAcrossCursorChanges() throws {
        var state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character("x"), .operatorSymbol("+"), .character("1")]),
                cursor: EditorCursor(path: [], offset: 0),
                selection: nil
            )
        )

        let first = state.mathFormulaSnapshot
        state.editorState.cursor = EditorCursor(path: [], offset: 3)
        let selectionData = Data(#"{"anchor":{"path":[],"offset":0},"focus":{"path":[],"offset":2}}"#.utf8)
        state.editorState.selection = try JSONDecoder().decode(EditorSelection.self, from: selectionData)
        let second = state.mathFormulaSnapshot

        XCTAssertEqual(first, second)
    }
}
