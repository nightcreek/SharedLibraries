import XCTest
@testable import EMathicaFormulaDisplayCore

final class FormulaLayoutEngineTests: XCTestCase {
    private let engine = FormulaLayoutEngine()

    func testSimpleTextLayoutHasNonzeroSize() {
        let box = engine.layout(.text("x", role: .symbol))
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testSimpleSequenceLayoutHasValidBaseline() {
        let box = engine.layout(.sequence([.text("x", role: .symbol), .operatorSymbol("+"), .text("1", role: .number)]))
        XCTAssertGreaterThanOrEqual(box.baseline, 0)
        XCTAssertLessThanOrEqual(box.baseline, box.size.height)
    }

    func testEmptySequenceLayoutIsSafe() {
        let box = engine.layout(.sequence([]))
        XCTAssertGreaterThanOrEqual(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testFractionHasNonzeroSize() {
        let box = engine.layout(.fraction(numerator: .text("x", role: .symbol), denominator: .text("2", role: .number)))
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testFractionNumeratorIsAboveDenominator() {
        let box = engine.layout(.fraction(numerator: .text("x", role: .symbol), denominator: .text("2", role: .number)))
        XCTAssertEqual(box.children.count, 2)
        let numerator = box.children[0]
        let denominator = box.children[1]
        XCTAssertLessThan(numerator.origin.y, denominator.origin.y)
    }

    func testFractionDenominatorIsBelowNumerator() {
        let box = engine.layout(.fraction(numerator: .text("x", role: .symbol), denominator: .text("2", role: .number)))
        let numerator = box.children[0]
        let denominator = box.children[1]
        XCTAssertGreaterThan(denominator.origin.y, numerator.origin.y + numerator.box.size.height / 2)
    }

    func testFractionBaselineIsWithinBounds() {
        let box = engine.layout(.fraction(numerator: .text("x", role: .symbol), denominator: .text("2", role: .number)))
        XCTAssertGreaterThanOrEqual(box.baseline, 0)
        XCTAssertLessThanOrEqual(box.baseline, box.size.height)
    }

    func testSqrtHasNonzeroSize() {
        let box = engine.layout(.sqrt(radicand: .text("x", role: .symbol)))
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testSqrtRadicandChildExists() {
        let box = engine.layout(.sqrt(radicand: .text("x", role: .symbol)))
        XCTAssertEqual(box.children.count, 1)
    }

    func testSqrtBaselineIsWithinBounds() {
        let box = engine.layout(.sqrt(radicand: .text("x", role: .symbol)))
        XCTAssertGreaterThanOrEqual(box.baseline, 0)
        XCTAssertLessThanOrEqual(box.baseline, box.size.height)
    }

    func testSuperscriptUsesSmallerChildSizeThanBase() {
        let box = engine.layout(.superscript(base: .text("x", role: .symbol), exponent: .text("2", role: .number)))
        let base = box.children[0].box
        let exponent = box.children[1].box
        XCTAssertLessThan(exponent.size.height, base.size.height)
    }

    func testSubscriptUsesSmallerChildSizeThanBase() {
        let box = engine.layout(.subscript(base: .text("x", role: .symbol), subscriptNode: .text("1", role: .number)))
        let base = box.children[0].box
        let subscriptBox = box.children[1].box
        XCTAssertLessThan(subscriptBox.size.height, base.size.height)
    }

    func testScriptPairSharesScriptColumn() {
        let box = engine.layout(.scriptPair(base: .text("x", role: .symbol), subscriptNode: .text("1", role: .number), superscriptNode: .text("2", role: .number)))
        XCTAssertEqual(box.children.count, 3)
        let superscriptChild = box.children[1]
        let subscriptChild = box.children[2]
        XCTAssertEqual(superscriptChild.origin.x, subscriptChild.origin.x)
    }

    func testScriptPairBaselineEqualsBaseBaseline() {
        let box = engine.layout(.scriptPair(base: .text("x", role: .symbol), subscriptNode: .text("1", role: .number), superscriptNode: .text("2", role: .number)))
        let base = box.children[0]
        XCTAssertEqual(box.baseline, base.origin.y + base.box.baseline, accuracy: 0.0001)
    }

    func testParenthesesExpandWidthBeyondContent() {
        let content = engine.layout(.text("x", role: .symbol))
        let box = engine.layout(.parentheses(content: .text("x", role: .symbol)))
        XCTAssertGreaterThan(box.size.width, content.size.width)
    }

    func testAbsoluteValueExpandsWidthBeyondContent() {
        let content = engine.layout(.text("x", role: .symbol))
        let box = engine.layout(.absoluteValue(content: .text("x", role: .symbol)))
        XCTAssertGreaterThan(box.size.width, content.size.width)
    }

    func testCursorLayoutHasNonzeroRect() {
        let box = engine.layout(.cursor)
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testPlaceholderLayoutHasNonzeroRect() {
        let box = engine.layout(.placeholder)
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testCursorAndPlaceholderSequenceHasBothChildren() {
        let box = engine.layout(.sequence([.cursor, .placeholder]))
        XCTAssertEqual(box.children.count, 2)
    }

    func testRawNodeHasNonzeroLayout() {
        let box = engine.layout(.raw(#"\unknown{x}"#))
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testErrorNodeHasNonzeroLayout() {
        let box = engine.layout(.error(.init(kind: .unknownCommand, rawText: #"\unknown{x}"#)))
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testGetPlanUsesLayoutSizeAndBaseline() {
        let plan = FormulaDisplayEngine().getPlan(from: .init(rawValue: #"\frac{x}{2}"#))
        guard let rootLayoutBox = plan.rootLayoutBox else {
            return XCTFail("Expected root layout box")
        }
        XCTAssertEqual(plan.size, rootLayoutBox.size)
        XCTAssertEqual(plan.baseline, rootLayoutBox.baseline, accuracy: 0.0001)
    }

    func testGetPlanForFractionKeepsNestedLayoutMetadata() {
        let fractionPlan = FormulaDisplayEngine().getPlan(from: .init(rawValue: #"\frac{x}{2}"#))
        let plainPlan = FormulaDisplayEngine().getPlan(from: .init(rawValue: "x"))
        XCTAssertNotNil(fractionPlan.rootLayoutBox)
        XCTAssertGreaterThanOrEqual(fractionPlan.size.height, plainPlan.size.height)
        XCTAssertEqual(fractionPlan.rootLayoutBox?.kind, .fraction)
    }
}
