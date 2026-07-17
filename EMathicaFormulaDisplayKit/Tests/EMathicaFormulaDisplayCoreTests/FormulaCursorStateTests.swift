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
}
