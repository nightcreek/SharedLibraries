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
        XCTAssertLessThan(box.children[1].origin.y, box.children[0].origin.y)
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

    func testNestedSuperscriptShrinksProgressively() {
        let box = engine.layout(
            .superscript(
                base: .text("x", role: .symbol),
                exponent: .superscript(
                    base: .text("x", role: .symbol),
                    exponent: .text("x", role: .symbol)
                )
            )
        )
        let outerExponent = box.children[1].box
        guard outerExponent.children.count == 2 else {
            return XCTFail("Expected nested script children")
        }
        let nestedBase = outerExponent.children[0].box
        let nestedExponent = outerExponent.children[1].box
        XCTAssertLessThan(outerExponent.size.height, box.children[0].box.size.height)
        XCTAssertLessThan(nestedExponent.size.height, nestedBase.size.height)
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

    func testParenthesesVerticallyCenterContent() {
        let box = engine.layout(.parentheses(content: .sequence([.text("x", role: .symbol), .operatorSymbol("+"), .text("1", role: .number)])))
        guard let content = box.children.first else {
            return XCTFail("Expected content child")
        }
        XCTAssertGreaterThan(content.origin.y, 0)
        XCTAssertLessThan(content.origin.y + content.box.size.height, box.size.height + 0.001)
    }

    func testParenthesesPlaceholderLeavesVisibleHorizontalGap() {
        let box = engine.layout(.parentheses(content: .anonymousPlaceholder))
        guard let content = box.children.first else {
            return XCTFail("Expected content child")
        }
        XCTAssertGreaterThan(content.origin.x, 2)
        XCTAssertGreaterThan(box.size.width - (content.origin.x + content.box.size.width), 2)
        XCTAssertLessThan(content.origin.x, 6.5)
    }

    func testAbsoluteValuePlaceholderLeavesVisibleHorizontalGap() {
        let box = engine.layout(.absoluteValue(content: .anonymousPlaceholder))
        guard let content = box.children.first else {
            return XCTFail("Expected content child")
        }
        XCTAssertGreaterThan(content.origin.x, 2)
        XCTAssertGreaterThan(box.size.width - (content.origin.x + content.box.size.width), 2)
        XCTAssertLessThan(content.origin.x, 5.5)
    }

    func testSqrtRadicandOffsetStaysCompactWithoutOverlap() {
        let box = engine.layout(.sqrt(radicand: .anonymousPlaceholder))
        guard let child = box.children.first else {
            return XCTFail("Expected radicand child")
        }
        XCTAssertGreaterThan(child.origin.x, 0)
        XCTAssertLessThan(child.origin.x, box.size.width * 0.32)
        XCTAssertGreaterThanOrEqual(child.origin.x, 2)
    }

    func testSqrtTopPaddingStaysCompact() {
        let box = engine.layout(.sqrt(radicand: .anonymousPlaceholder))
        guard let child = box.children.first else {
            return XCTFail("Expected radicand child")
        }
        XCTAssertGreaterThan(child.origin.y, 0)
        XCTAssertLessThan(child.origin.y, 3.0)
    }

    func testFunctionPlaceholderHasPositiveGap() {
        let box = engine.layout(.function(name: "sin", arguments: [.anonymousPlaceholder]))
        XCTAssertEqual(box.children.count, 2)
        let functionName = box.children[0]
        let placeholder = box.children[1]
        XCTAssertGreaterThan(placeholder.origin.x - functionName.box.size.width, 0)
        XCTAssertLessThan(placeholder.origin.x - functionName.box.size.width, 4)
    }

    func testPunctuationHeavyTextUsesNarrowerWidthEstimate() {
        let metrics = FormulaLayoutMetrics.default
        let box = FormulaLayoutEngine(metrics: metrics).layout(.text("x(t)=", role: .raw))
        let naiveWidth = 5.0 * metrics.baseFontSize * 0.6
        XCTAssertLessThan(box.size.width, naiveWidth)
    }

    func testParametricLayoutUsesCompactLabelWidth() {
        let box = engine.layout(.parametric2D(x: .text("x", role: .symbol), y: .text("y", role: .symbol), range: .text("t>0", role: .raw)))
        XCTAssertLessThan(box.size.width, 110)
    }

    func testParametricLayoutProducesMultipleRows() {
        let box = engine.layout(.parametric2D(x: .text("x", role: .symbol), y: .text("y", role: .symbol), range: .text("t", role: .symbol)))
        XCTAssertEqual(box.kind, .parametric2D)
        XCTAssertGreaterThanOrEqual(box.children.count, 5)
        XCTAssertGreaterThan(box.size.height, FormulaLayoutMetrics.default.minimumBoxSize.height)
    }

    func testPiecewiseLayoutProducesMultipleRows() {
        let box = engine.layout(
            .piecewise(
                rows: [
                    .init(expression: .text("x", role: .symbol), condition: .text("0", role: .number)),
                    .init(expression: .text("y", role: .symbol), condition: .text("1", role: .number))
                ]
            )
        )
        XCTAssertEqual(box.kind, .piecewise)
        XCTAssertEqual(box.children.count, 4)
        XCTAssertGreaterThan(box.size.height, FormulaLayoutMetrics.default.minimumBoxSize.height)
    }

    func testCursorLayoutHasNonzeroRect() {
        let box = engine.layout(.anonymousCursor)
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testPlaceholderLayoutHasNonzeroRect() {
        let box = engine.layout(.anonymousPlaceholder)
        XCTAssertGreaterThan(box.size.width, 0)
        XCTAssertGreaterThan(box.size.height, 0)
    }

    func testCursorAndPlaceholderSequenceHasBothChildren() {
        let box = engine.layout(.sequence([.anonymousCursor, .anonymousPlaceholder]))
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
