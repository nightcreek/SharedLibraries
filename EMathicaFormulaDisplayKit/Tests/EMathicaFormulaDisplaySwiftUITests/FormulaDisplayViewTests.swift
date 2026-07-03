import SwiftUI
import XCTest
@testable import EMathicaFormulaDisplaySwiftUI
import EMathicaFormulaDisplayCore

final class FormulaDisplayViewTests: XCTestCase {
    func testFormulaDisplayViewCanInitializeFromRawValue() {
        let view = FormulaDisplayView(rawValue: "x+1")
        XCTAssertNotNil(view)
    }

    func testFormulaDisplayViewCanInitializeFromMarkup() {
        let view = FormulaDisplayView(markup: FormulaDisplayMarkup(rawValue: "x+1"))
        XCTAssertNotNil(view)
    }

    func testFormulaDisplayViewCanInitializeFromPlan() {
        let plan = FormulaDisplayEngine().getPlan(from: FormulaDisplayMarkup(rawValue: "x+1"))
        let view = FormulaDisplayView(plan: plan)
        XCTAssertNotNil(view)
    }

    func testSwiftUITargetUsesCoreSurfaceForPlanConstruction() {
        let markup = FormulaDisplayMarkup(rawValue: "x+1")
        let plan = FormulaDisplayEngine().getPlan(from: markup)
        let view = FormulaDisplayView(plan: plan)
        XCTAssertNotNil(view)
    }
}
