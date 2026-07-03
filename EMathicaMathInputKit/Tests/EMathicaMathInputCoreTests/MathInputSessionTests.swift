import XCTest
@testable import EMathicaMathInputCore

final class MathInputSessionTests: XCTestCase {
    func testSessionApplyExportImportAndReset() throws {
        let session = MathInputSession()

        session.apply(.insertCharacter("x"))

        XCTAssertFalse(session.sourceText.isEmpty)
        XCTAssertFalse(session.displayLatex.isEmpty)
        XCTAssertFalse(session.computeExpression.isEmpty)

        let exported = try session.exportEditorStateJSON(prettyPrinted: true)
        XCTAssertFalse(exported.isEmpty)

        let imported = MathInputSession()
        try imported.importEditorStateJSON(exported)
        XCTAssertEqual(imported.sourceText, session.sourceText)

        imported.reset()
        XCTAssertTrue(imported.sourceText.isEmpty)
    }

    func testLatexoutProducesCleanLatexWithoutCursorMarkers() {
        let session = MathInputSession()

        session.apply(.insertCharacter("x"))
        session.apply(.insertTemplate(.superscript))
        session.apply(.insertCharacter("2"))
        session.apply(.tab)
        session.apply(.insertOperator("+"))
        session.apply(.insertCharacter("1"))

        XCTAssertEqual(session.latexout(), "x^{2}+1")
        XCTAssertFalse(session.latexout().contains(#"\cursor{}"#))
        XCTAssertFalse(session.latexout().contains(#"\placeholder{}"#))
    }

    func testLatexoutAndDisplayoutStayDistinctForEmptyTemplateFields() {
        let session = MathInputSession()

        session.apply(.insertTemplate(.fraction))
        session.apply(.insertCharacter("x"))
        session.apply(.tab)

        XCTAssertEqual(session.latexout(), #"\frac{x}{}"#)
        XCTAssertEqual(session.displayout().rawValue, #"\frac{x}{\cursor{}\placeholder{}}"#)
    }

    func testDisplayoutReflectsCurrentCursorWithoutChangingFormulaOrDerivedStrings() {
        let session = MathInputSession()

        session.apply(.insertTemplate(.fraction))
        session.apply(.insertCharacter("x"))
        session.apply(.tab)

        let formulaBefore = session.formula()
        let sourceBefore = session.sourceText
        let computeBefore = session.computeExpression

        XCTAssertEqual(session.displayout().rawValue, #"\frac{x}{\cursor{}\placeholder{}}"#)
        XCTAssertEqual(session.formula(), formulaBefore)
        XCTAssertEqual(session.sourceText, sourceBefore)
        XCTAssertEqual(session.computeExpression, computeBefore)
    }

    func testUndoRedoRestoresFormulaLatexAndDisplayProjection() {
        let session = MathInputSession()

        session.apply(.insertCharacter("x"))
        session.apply(.insertOperator("+"))
        session.apply(.insertCharacter("1"))

        XCTAssertTrue(session.canUndo)
        XCTAssertFalse(session.canRedo)
        XCTAssertEqual(session.latexout(), "x+1")

        session.undo()

        XCTAssertEqual(session.latexout(), "x+")
        XCTAssertEqual(
            session.formula(),
            .sequence([.symbol("x"), .operatorSymbol("+")])
        )
        XCTAssertEqual(session.displayout().rawValue, #"x+\cursor{}"#)
        XCTAssertTrue(session.canRedo)

        session.redo()

        XCTAssertEqual(session.latexout(), "x+1")
        XCTAssertEqual(
            session.formula(),
            .sequence([.symbol("x"), .operatorSymbol("+"), .number("1")])
        )
        XCTAssertEqual(session.displayout().rawValue, #"x+1\cursor{}"#)
    }
}
