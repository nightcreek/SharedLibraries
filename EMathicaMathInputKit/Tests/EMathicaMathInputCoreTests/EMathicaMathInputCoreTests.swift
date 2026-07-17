import XCTest
@testable import EMathicaMathInputCore

final class EMathicaMathInputCoreTests: XCTestCase {

    private func projectedSource(_ state: EditorState) -> String {
        SourceSerializer().project(state).source
    }

    // MARK: - Basic Input

    func testBasicInsertAndSerialization() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)

        let projection = SourceSerializer().project(state)
        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)

        XCTAssertFalse(projection.source.isEmpty)
        XCTAssertFalse(latex.isEmpty)
    }

    func testInsertX2Plus1() {
        var state = EditorState()
        let controller = InputController()

        // Type: x ^ 2 + 1
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.insertCharacter("2"), state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.insertOperator("+"), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)

        let projection = SourceSerializer().project(state)
        XCTAssertTrue(projection.source.contains("x"))
        XCTAssertTrue(projection.source.contains("2"))
        XCTAssertTrue(projection.source.contains("+"))
        XCTAssertTrue(projection.source.contains("1"))
    }

    // MARK: - Template Insertion

    func testSuperscriptTemplate() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertTemplate(.superscript), state: &state)

        let projection = SourceSerializer().project(state)
        XCTAssertTrue(projection.source.contains("x"))
    }

    func testFractionTemplate() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertTemplate(.fraction), state: &state)

        let projection = SourceSerializer().project(state)
        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        XCTAssertFalse(projection.source.isEmpty)
        XCTAssertTrue(latex.contains("\\frac"))
    }

    func testSquareRootTemplate() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertTemplate(.sqrt), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.tab, state: &state)

        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        XCTAssertTrue(latex.contains("\\sqrt"))
    }

    // MARK: - Cursor Movement

    func testCursorMoveLeft() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("a"), state: &state)
        controller.handle(.insertCharacter("b"), state: &state)

        // Cursor should be at end
        XCTAssertEqual(state.cursor.offset, 2)

        controller.handle(.moveLeft, state: &state)
        XCTAssertEqual(state.cursor.offset, 1)

        controller.handle(.moveLeft, state: &state)
        XCTAssertEqual(state.cursor.offset, 0)
    }

    func testCursorMoveRight() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("a"), state: &state)
        controller.handle(.insertCharacter("b"), state: &state)

        // Move to start
        controller.handle(.moveLeft, state: &state)
        controller.handle(.moveLeft, state: &state)
        XCTAssertEqual(state.cursor.offset, 0)

        controller.handle(.moveRight, state: &state)
        XCTAssertEqual(state.cursor.offset, 1)
    }

    func testDeleteBackward() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertCharacter("y"), state: &state)
        XCTAssertEqual(state.cursor.offset, 2)

        controller.handle(.deleteBackward, state: &state)
        let projection = SourceSerializer().project(state)
        XCTAssertEqual(projection.source, "x")
        XCTAssertEqual(state.cursor.offset, 1)
    }

    func testDeleteBackwardAfterFractionBoundaryReturnsToNumeratorThenDeletesFraction() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.tab, state: &state)

        controller.handle(.deleteBackward, state: &state)
        XCTAssertEqual(state.cursor.path, [.sequenceIndex(0), .templateField(.numerator)])
        XCTAssertEqual(state.cursor.offset, 1)

        controller.handle(.deleteBackward, state: &state)
        controller.handle(.deleteBackward, state: &state)

        XCTAssertEqual(projectedSource(state), "")
        XCTAssertEqual(state.cursor.path, [])
        XCTAssertEqual(state.cursor.offset, 0)
    }

    func testDeleteBackwardOnEmptySqrtRemovesStructure() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertTemplate(.sqrt), state: &state)
        controller.handle(.deleteBackward, state: &state)

        XCTAssertEqual(projectedSource(state), "")
        XCTAssertEqual(state.cursor.path, [])
        XCTAssertEqual(state.cursor.offset, 0)
    }

    func testDeleteBackwardOnEmptySuperscriptUnwrapsBase() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertTemplate(.superscript), state: &state)
        controller.handle(.deleteBackward, state: &state)

        XCTAssertEqual(projectedSource(state), "x")
        XCTAssertEqual(state.cursor.path, [])
        XCTAssertEqual(state.cursor.offset, 1)
    }

    func testLegacyAliasesMapToCanonicalActions() {
        XCTAssertEqual(InputController.canonicalAction(for: .backspace), .deleteBackward)
        XCTAssertEqual(InputController.canonicalAction(for: .delete), .deleteForward)
        XCTAssertEqual(InputController.canonicalAction(for: .enter), .submit)
        XCTAssertEqual(InputController.canonicalAction(for: .moveLeft), .moveLeft)
    }

    func testBackspaceAtStartIsStable() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.backspace, state: &state)

        XCTAssertEqual(projectedSource(state), "")
        XCTAssertEqual(state.cursor.offset, 0)
    }

    func testDeleteForwardAtEndIsStable() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.deleteForward, state: &state)

        XCTAssertEqual(projectedSource(state), "x")
        XCTAssertEqual(state.cursor.offset, 1)
    }

    func testMoveLeftAndMoveRightStayWithinBounds() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.moveLeft, state: &state)
        XCTAssertEqual(state.cursor.offset, 0)

        controller.handle(.insertCharacter("a"), state: &state)
        controller.handle(.moveLeft, state: &state)
        controller.handle(.moveLeft, state: &state)
        XCTAssertEqual(state.cursor.offset, 0)

        controller.handle(.moveRight, state: &state)
        controller.handle(.moveRight, state: &state)
        XCTAssertEqual(state.cursor.offset, 1)
    }

    func testDeleteBackwardRemovesSelectedRange() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertCharacter("y"), state: &state)
        controller.handle(.insertCharacter("z"), state: &state)
        state.selection = EditorSelection(
            anchor: EditorCursor(path: [], offset: 1),
            focus: EditorCursor(path: [], offset: 3)
        )

        controller.handle(.deleteBackward, state: &state)

        XCTAssertEqual(projectedSource(state), "x")
        XCTAssertEqual(state.cursor.offset, 1)
        XCTAssertNil(state.selection)
    }

    func testInsertCharacterReplacesSelectedRange() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertCharacter("y"), state: &state)
        controller.handle(.insertCharacter("z"), state: &state)
        state.selection = EditorSelection(
            anchor: EditorCursor(path: [], offset: 0),
            focus: EditorCursor(path: [], offset: 2)
        )

        controller.handle(.insertCharacter("a"), state: &state)

        XCTAssertEqual(projectedSource(state), "az")
        XCTAssertEqual(state.cursor.offset, 1)
        XCTAssertNil(state.selection)
    }

    func testSubmitDoesNotMutateEditorState() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("x"), state: &state)
        let before = state

        controller.handle(.submit, state: &state)
        controller.handle(.enter, state: &state)

        XCTAssertEqual(state, before)
    }

    // MARK: - Serialization Round Trip

    func testLaTeXRoundTrip() {
        var state = EditorState()
        let controller = InputController()

        // Type: x + 1
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertOperator("+"), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)

        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        XCTAssertTrue(latex.contains("x"))
        XCTAssertTrue(latex.contains("+"))
        XCTAssertTrue(latex.contains("1"))

        // Parse back
        guard let parsed = SimpleMathParser().parseLatex(latex) else {
            XCTFail("Failed to parse LaTeX: \(latex)")
            return
        }
        let reparsedLatex = LatexMathRenderer().renderLatex(parsed, editing: false)
        XCTAssertFalse(reparsedLatex.isEmpty)
    }

    func testSourceRoundTrip() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertCharacter("f"), state: &state)
        controller.handle(.insertCharacter("("), state: &state)
        controller.handle(.insertCharacter("x"), state: &state)
        controller.handle(.insertCharacter(")"), state: &state)

        let projection = SourceSerializer().project(state)
        XCTAssertTrue(projection.source.contains("f"))
        XCTAssertTrue(projection.source.contains("x"))
    }

    // MARK: - Placeholder Navigation

    func testPlaceholderNavigationAfterTemplate() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertTemplate(.fraction), state: &state)

        // After inserting fraction, should start in numerator (first placeholder)
        controller.handle(.insertCharacter("1"), state: &state)

        controller.handle(.tab, state: &state)
        // Now in denominator
        controller.handle(.insertCharacter("2"), state: &state)

        controller.handle(.tab, state: &state)
        // Now after fraction

        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        XCTAssertTrue(latex.contains("\\frac"))
        XCTAssertTrue(latex.contains("1"))
        XCTAssertTrue(latex.contains("2"))
    }

    func testPlaceholderNavigationBackward() {
        var state = EditorState()
        let controller = InputController()

        controller.handle(.insertTemplate(.fraction), state: &state)
        controller.handle(.insertCharacter("1"), state: &state)
        controller.handle(.tab, state: &state)
        controller.handle(.insertCharacter("2"), state: &state)

        // Navigate back
        controller.handle(.shiftTab, state: &state)

        let latex = LatexMathRenderer().renderLatex(state.root, editing: true)
        XCTAssertTrue(latex.contains("1"))
        XCTAssertTrue(latex.contains("2"))
    }

    // MARK: - Character Normalization

    func testNormalizerIdentity() {
        XCTAssertEqual(MathInputCharacterNormalizer.normalize("x"), "x")
        XCTAssertEqual(MathInputCharacterNormalizer.normalize("1"), "1")
        XCTAssertEqual(MathInputCharacterNormalizer.normalize("+"), "+")
    }

    // MARK: - MathInputSession

    func testInputSession() {
        let session = MathInputSession()

        session.apply(.insertCharacter("x"))
        session.apply(.insertCharacter("^"))
        session.apply(.insertCharacter("2"))

        XCTAssertFalse(session.sourceText.isEmpty)
        XCTAssertTrue(session.sourceText.contains("x"))
        XCTAssertTrue(session.displayLatex.contains("x"))
    }

    func testInputSessionRoundTrip() throws {
        let session = MathInputSession()

        session.apply(.insertCharacter("y"))
        session.apply(.insertOperator("="))
        session.apply(.insertCharacter("m"))
        session.apply(.insertCharacter("x"))
        session.apply(.insertOperator("+"))
        session.apply(.insertCharacter("b"))

        // Export → Import
        let json = try session.exportEditorStateJSON()
        let session2 = MathInputSession()
        try session2.importEditorStateJSON(json)

        XCTAssertEqual(session2.sourceText, session.sourceText)
    }

    // MARK: - Codable Support

    func testEditorStateCodable() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertCharacter("x"), state: &state)

        let data = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(EditorState.self, from: data)

        let projection = SourceSerializer().project(decoded)
        XCTAssertEqual(projection.source, "x")
    }

    func testMathNodeCodable() throws {
        var state = EditorState()
        let controller = InputController()
        controller.handle(.insertTemplate(.fraction), state: &state)

        let data = try JSONEncoder().encode(state.root)
        let decoded = try JSONDecoder().decode(MathNode.self, from: data)

        let latex = LatexMathRenderer().renderLatex(decoded, editing: true)
        XCTAssertTrue(latex.contains("\\frac"))
    }
}
