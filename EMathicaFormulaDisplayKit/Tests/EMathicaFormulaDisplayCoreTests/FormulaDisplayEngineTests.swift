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
                    return element.text == "x+1"
                }
                return false
            }
        )
    }

    func testCoreSurfaceCompilesWithoutSwiftUITypes() {
        let engine = FormulaDisplayEngine(
            options: .default,
            metrics: .default
        )
        let plan = engine.getPlan(from: "x")
        XCTAssertEqual(plan.hitRegions.count, 1)
    }
}
