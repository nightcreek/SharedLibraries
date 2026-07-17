import EMathicaFormulaDisplayCore
import EMathicaMathInputCore
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

    func testFormulaEditingDisplayViewCanInitializeWithoutChangingInteractionModel() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character("x"), .operatorSymbol("\\leq"), .character("2")]),
                cursor: EditorCursor(path: [], offset: 3),
                selection: nil
            )
        )

        let view = FormulaEditingDisplayView(
            inputState: state,
            isFocused: true,
            onTapCursor: { _ in },
            onKeyboardAction: { _ in }
        )

        XCTAssertNotNil(view)
    }

    func testEditingDisplayBridgeRendersLeqAsVisibleFormulaSymbol() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character("x"), .operatorSymbol("\\leq"), .character("2")]),
                cursor: EditorCursor(path: [], offset: 3),
                selection: nil
            )
        )

        let rawValue = state.displayMarkupSnapshot.rawValue
        let plan = FormulaDisplayEngine().getPlan(from: .init(rawValue: rawValue))

        XCTAssertTrue(rawValue.contains(#"\leq"#))
        XCTAssertTrue(
            plan.elements.contains {
                if case .text(let element) = $0 {
                    return element.text == "≤"
                }
                return false
            }
        )
        XCTAssertFalse(
            plan.elements.contains {
                if case .text(let element) = $0 {
                    return element.text.contains(#"\leq"#)
                }
                return false
            }
        )
    }

    func testMathInputDisplayoutFeedsFormulaDisplayEngine() {
        let session = MathInputSession()
        session.input(.template(.fraction))
        session.input(.char("x"))
        session.input(.control(.nextSlot))

        let state = FormulaInputState(editorState: session.editorState)

        let rawValue = state.displayMarkupSnapshot.rawValue
        let plan = FormulaDisplayEngine().getPlan(from: .init(rawValue: rawValue))

        XCTAssertTrue(rawValue.contains(#"\frac"#))
        XCTAssertTrue(rawValue.contains(#"\cursor{}"#))
        XCTAssertTrue(rawValue.contains(#"\placeholder{}"#))
        XCTAssertFalse(plan.elements.isEmpty)
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertFalse(plan.cursorRects.isEmpty)
        XCTAssertFalse(plan.placeholderRects.isEmpty)
    }

    func testRawLatexFallbackRemainsVisibleAcrossDisplayBridge() {
        let state = FormulaInputState(
            editorState: EditorState(
                root: .sequence([.character(".")]),
                cursor: EditorCursor(path: [], offset: 1),
                selection: nil
            )
        )

        let rawValue = state.displayMarkupSnapshot.rawValue
        let plan = FormulaDisplayEngine().getPlan(from: .init(rawValue: rawValue))

        XCTAssertFalse(rawValue.isEmpty)
        XCTAssertFalse(plan.elements.isEmpty)
        XCTAssertTrue(
            plan.elements.contains { element in
                if case .text(let text) = element {
                    return !text.text.isEmpty
                }
                return false
            }
        )
    }
}
