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

    func testInputTokenFacadeCoversCoreTokenKinds() {
        let session = MathInputSession()

        session.input(.char("x"))
        session.input(.template(.superscript))
        session.input(.number("2"))
        session.input(.control(.nextSlot))
        session.input(.op("+"))
        session.input(.template(.fraction))
        session.input(.char("1"))
        session.input(.control(.nextSlot))
        session.input(.number("2"))
        session.input(.control(.previousSlot))
        session.input(.control(.moveLeft))
        session.input(.control(.deleteBackward))
        session.input(.function("sin"))
        session.input(.char("x"))

        XCTAssertTrue(session.latexout().contains(#"\sin(x)"#))
        XCTAssertFalse(session.latexout().contains(#"\cursor{}"#))
        XCTAssertNotEqual(session.formula(), .sequence([]))
    }

    func testInputControlUndoAndRedoUseSessionHistory() {
        let session = MathInputSession()

        session.input(.char("x"))
        session.input(.op("+"))
        session.input(.number("1"))
        XCTAssertEqual(session.latexout(), "x+1")

        session.input(.control(.undo))
        XCTAssertEqual(session.latexout(), "x+")

        session.input(.control(.redo))
        XCTAssertEqual(session.latexout(), "x+1")
    }

    func testLatexinSupportsCoreSubsetAndContinuesEditingAST() {
        let session = MathInputSession()

        XCTAssertTrue(session.latexin(#"\frac{x}{2}"#))
        XCTAssertEqual(session.latexout(), #"\frac{x}{2}"#)
        XCTAssertEqual(session.displayout().rawValue, #"\frac{x}{2}\cursor{}"#)

        session.input(.op("+"))
        session.input(.number("1"))

        XCTAssertEqual(session.latexout(), #"\frac{x}{2}+1"#)
    }

    func testLatexinSupportsFunctionsParenthesesAndAbsoluteValueSubset() {
        let cases: [(String, String)] = [
            ("x", "x"),
            ("x+1", "x+1"),
            ("x^2", "x^{2}"),
            (#"\sqrt{x}"#, #"\sqrt{x}"#),
            (#"\sin(x)"#, #"\sin(x)"#),
            (#"\cos(x)"#, #"\cos(x)"#),
            (#"\tan(x)"#, #"\tan(x)"#),
            (#"\ln(x)"#, #"\ln(x)"#),
            (#"\log(x)"#, #"\log(x)"#),
            ("(x+1)", "(x+1)"),
            ("|x|", #"\left|x\right|"#)
        ]

        for (input, expectedLatex) in cases {
            let session = MathInputSession()
            XCTAssertTrue(session.latexin(input), "Expected latexin to accept \(input)")
            XCTAssertEqual(session.latexout(), expectedLatex)
            XCTAssertFalse(session.displayout().rawValue.isEmpty)
        }
    }

    func testDisplayoutProjectsStructuredPiecewiseMarkup() {
        let session = MathInputSession()

        session.apply(.insertTemplate(.piecewise(rows: 2)))
        session.apply(.insertCharacter("x"))
        session.apply(.moveRight)
        session.apply(.insertCharacter("0"))
        session.apply(.moveRight)
        session.apply(.insertCharacter("y"))
        session.apply(.moveRight)
        session.apply(.insertCharacter("1"))

        XCTAssertEqual(
            session.displayout().rawValue,
            #"\piecewise{x}{0}{y}{1\cursor{}}"#
        )
    }

    func testDisplayoutProjectsStructuredParametricMarkup() {
        let session = MathInputSession()

        session.apply(.insertTemplate(.parametricEquation2D))
        session.apply(.insertCharacter("x"))
        session.apply(.moveDown)
        session.apply(.insertCharacter("y"))
        session.apply(.moveDown)
        session.apply(.insertCharacter("t"))

        XCTAssertEqual(
            session.displayout().rawValue,
            #"\parametric{x}{y}{t\cursor{}}"#
        )
    }
}
