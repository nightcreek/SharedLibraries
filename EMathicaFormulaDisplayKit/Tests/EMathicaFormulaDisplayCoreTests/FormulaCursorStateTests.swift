import XCTest
@testable import EMathicaFormulaDisplayCore

final class FormulaCursorStateTests: XCTestCase {
    func testSingleInsertionPointHasNoSelectionState() {
        let anchor = FormulaCursorAnchor(
            rect: .init(origin: .init(x: 10, y: 4), size: .init(width: 1, height: 18)),
            baseline: 14
        )

        let state = FormulaCursorState(insertionPoint: anchor)

        XCTAssertEqual(state.insertionPoint, anchor)
        XCTAssertNil(state.insertionPoint.offset)
        XCTAssertNil(state.selectionEnd)
        XCTAssertNil(state.selectionState)
    }

    func testSelectionStateUsesInsertionPointAndSelectionEnd() {
        let start = FormulaCursorAnchor(
            rect: .init(origin: .init(x: 10, y: 4), size: .init(width: 1, height: 18)),
            baseline: 14
        )
        let end = FormulaCursorAnchor(
            rect: .init(origin: .init(x: 28, y: 4), size: .init(width: 1, height: 18)),
            baseline: 14
        )

        let state = FormulaCursorState(
            insertionPoint: start,
            selectionEnd: end
        )

        XCTAssertEqual(state.selectionEnd, end)
        XCTAssertEqual(
            state.selectionState,
            FormulaSelectionState(startAnchor: start, endAnchor: end)
        )
    }

    func testCursorAnchorCanCarryStructuredOffsetIdentity() {
        let anchor = FormulaCursorAnchor(
            id: "cursor:field.argument@2",
            rect: .init(origin: .init(x: 14, y: 3), size: .init(width: 1, height: 17)),
            x: 14,
            baseline: 15,
            ascent: 7,
            descent: 10,
            offset: 2,
            context: .radicalRadicand,
            sourcePath: ["field.argument"],
            fieldIdentity: "argument"
        )

        XCTAssertEqual(anchor.offset, 2)
        XCTAssertEqual(anchor.fieldIdentity, "argument")
        XCTAssertEqual(anchor.sourcePath, ["field.argument"])
        XCTAssertEqual(anchor.context, .radicalRadicand)
    }
}
