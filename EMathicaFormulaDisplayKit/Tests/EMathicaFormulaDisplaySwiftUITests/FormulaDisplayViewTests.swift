import SwiftUI
import XCTest
@testable import EMathicaFormulaDisplaySwiftUI
import EMathicaFormulaDisplayCore

@MainActor
final class FormulaDisplayViewTests: XCTestCase {
    func testFormulaDisplayViewCanInitializeFromRawValue() {
        let factory: @MainActor (String) -> FormulaDisplayView = FormulaDisplayView.init(rawValue:)
        let type = factory("x+1")
        XCTAssertNotNil(type)
    }

    func testFormulaDisplayViewCanInitializeFromMarkup() {
        let factory: @MainActor (FormulaDisplayMarkup) -> FormulaDisplayView = FormulaDisplayView.init(markup:)
        let type = factory(FormulaDisplayMarkup(rawValue: "x+1"))
        XCTAssertNotNil(type)
    }

    func testFormulaDisplayViewCanInitializeFromPlan() {
        let plan = FormulaDisplayEngine().getPlan(from: FormulaDisplayMarkup(rawValue: "x+1"))
        let factory: @MainActor (FormulaRenderPlan) -> FormulaDisplayView = FormulaDisplayView.init(plan:)
        let type = factory(plan)
        XCTAssertNotNil(type)
    }

    func testSwiftUITargetUsesCoreSurfaceForPlanConstruction() {
        let markup = FormulaDisplayMarkup(rawValue: "x+1")
        let plan = FormulaDisplayEngine().getPlan(from: markup)
        let factory: @MainActor (FormulaRenderPlan) -> FormulaDisplayView = FormulaDisplayView.init(plan:)
        let type = factory(plan)
        XCTAssertNotNil(type)
    }
}
