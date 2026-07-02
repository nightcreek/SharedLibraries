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
}
