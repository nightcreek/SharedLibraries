import XCTest
@testable import EMathicaMathInputCore

final class FormulaDisplayProjectionTests: XCTestCase {
    func testFormulaProjectionIgnoresCursorAndSelectionState() {
        let root = MathNode.sequence([
            .character("x"),
            .operatorSymbol("+"),
            .character("1")
        ])

        let leftState = EditorState(
            root: root,
            cursor: EditorCursor(path: [], offset: 0),
            selection: nil
        )
        let selectedState = EditorState(
            root: root,
            cursor: EditorCursor(path: [], offset: 3),
            selection: EditorSelection(
                anchor: EditorCursor(path: [], offset: 0),
                focus: EditorCursor(path: [], offset: 2)
            )
        )

        XCTAssertEqual(
            MathFormulaProjection.snapshot(from: leftState.root),
            MathFormulaProjection.snapshot(from: selectedState.root)
        )
    }

    func testDisplayProjectionIsPureAndDoesNotMutateFormula() {
        let formula = MathFormula.template(
            MathTemplateFormula(
                kind: .fraction,
                fields: [
                    .sequence([.symbol("x")]),
                    .sequence([])
                ]
            )
        )

        let before = formula
        let first = FormulaDisplayProjection.displayout(source: formula, cursor: nil)
        let second = FormulaDisplayProjection.displayout(source: formula, cursor: nil)

        XCTAssertEqual(formula, before)
        XCTAssertEqual(first, second)
        XCTAssertEqual(first.rawValue, #"\frac{x}{\placeholder{}}"#)
    }

    func testDisplayProjectionAcceptsExternalCursorStateWithoutEmbeddingItInFormula() {
        let formula = MathFormula.sequence([.symbol("x")])
        let cursor = FormulaDisplayCursorState(
            editorCursor: EditorCursor(path: [], offset: 1)
        )

        let markup = FormulaDisplayProjection.displayout(source: formula, cursor: cursor)

        XCTAssertEqual(formula, .sequence([.symbol("x")]))
        XCTAssertEqual(markup.rawValue, "x")
    }

    func testProjectionSnapshotValidationAcceptsCurrentFormulaValues() {
        let formula = MathFormula.sequence([
            .function(
                MathFunctionFormula(
                    name: "sin",
                    arguments: [.sequence([.symbol("x")])]
                )
            ),
            .template(
                MathTemplateFormula(
                    kind: .fraction,
                    fields: [.sequence([.number("1")]), .sequence([.number("2")])]
                )
            )
        ])

        MathInputArchitectureInvariants.validateProjectionSnapshot(formula)
    }
}
