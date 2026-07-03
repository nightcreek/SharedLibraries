import XCTest
@testable import EMathicaFormulaDisplayCore

final class FormulaDisplayEngineTests: XCTestCase {
    func testMarkupPreservesRawValue() {
        let markup = FormulaDisplayMarkup(rawValue: "x+1")
        XCTAssertEqual(markup.rawValue, "x+1")
    }

    func testEngineReturnsValidPlanForSimpleExpression() {
        let plan = FormulaDisplayEngine().getPlan(from: FormulaDisplayMarkup(rawValue: "x+1"))
        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertGreaterThan(plan.size.height, 0)
        XCTAssertGreaterThanOrEqual(plan.baseline, 0)
        XCTAssertNotNil(plan.rootLayoutBox)
    }

    func testEmptyMarkupDoesNotCrash() {
        let plan = FormulaDisplayEngine().getPlan(from: FormulaDisplayMarkup(rawValue: ""))
        XCTAssertEqual(plan.rootNode, .sequence([]))
        XCTAssertGreaterThanOrEqual(plan.size.width, 0)
        XCTAssertGreaterThanOrEqual(plan.size.height, 0)
    }

    func testPlanContainsTextElementForSimpleExpression() {
        let plan = FormulaDisplayEngine().getPlan(from: FormulaDisplayMarkup(rawValue: "x+1"))
        XCTAssertTrue(
            plan.elements.contains {
                if case .text(let element) = $0 {
                    return ["x", "+", "1"].contains(element.text)
                }
                return false
            }
        )
        XCTAssertEqual(
            plan.rootNode,
            .sequence([
                .text("x", role: .symbol),
                .operatorSymbol("+"),
                .text("1", role: .number)
            ])
        )
    }

    func testCoreSurfaceCompilesWithoutSwiftUITypes() {
        let engine = FormulaDisplayEngine(
            options: .default,
            metrics: .default
        )
        let plan = engine.getPlan(from: "x")
        XCTAssertEqual(plan.hitRegions.count, 1)
        XCTAssertEqual(plan.rootLayoutBox?.kind, .text)
    }

    func testParserBackedPlanStillHandlesDisplayMarkupMarkers() {
        let plan = FormulaDisplayEngine().getPlan(
            from: FormulaDisplayMarkup(rawValue: #"\frac{x}{\cursor{}\placeholder{}}"#)
        )

        XCTAssertFalse(plan.cursorRects.isEmpty)
        XCTAssertFalse(plan.placeholderRects.isEmpty)
        XCTAssertEqual(
            plan.rootNode,
            .fraction(
                numerator: .text("x", role: .symbol),
                denominator: .sequence([.cursor, .placeholder])
            )
        )
    }
}
