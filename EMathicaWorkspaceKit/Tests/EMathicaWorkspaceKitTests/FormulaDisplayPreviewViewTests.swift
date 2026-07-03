import SwiftUI
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class FormulaDisplayPreviewViewTests: XCTestCase {
    func testFormulaDisplayPreviewViewCanInitializeFromRawValue() {
        let view = FormulaDisplayPreviewView(rawValue: "x+1")
        XCTAssertNotNil(view)
    }

    func testFormulaDisplayPreviewViewCanInitializeFromInputState() {
        let state = FormulaInputState()
        let view = FormulaDisplayPreviewView(inputState: state)
        XCTAssertNotNil(view)
    }

    func testPreviewBridgeUsesDisplayMarkupRawValueWithoutChangingSource() {
        var state = FormulaInputState()
        state.source = "x+1"
        let sourceBefore = state.source
        let displayLatexBefore = state.displayLatex
        let expectedRawValue = state.displayMarkupSnapshot.rawValue

        let view = FormulaDisplayPreviewView(inputState: state)

        XCTAssertNotNil(view)
        XCTAssertEqual(state.displayMarkupSnapshot.rawValue, expectedRawValue)
        XCTAssertEqual(state.source, sourceBefore)
        XCTAssertEqual(state.displayLatex, displayLatexBefore)
    }

    func testPreviewBridgePreservesDisplayLatexFallback() {
        let state = FormulaInputState(
            source: "x+1",
            displayLatex: "x+1"
        )

        let view = FormulaDisplayPreviewView(inputState: state)

        XCTAssertNotNil(view)
        XCTAssertEqual(state.displayLatex, "x+1")
        XCTAssertEqual(state.source, "x+1")
    }

    func testWorkspaceKitCanImportFormulaDisplaySwiftUIThroughPreviewBridge() {
        let view = FormulaDisplayPreviewView(rawValue: #"\frac{x}{\placeholder{}}"#)
        XCTAssertNotNil(view)
    }
}
