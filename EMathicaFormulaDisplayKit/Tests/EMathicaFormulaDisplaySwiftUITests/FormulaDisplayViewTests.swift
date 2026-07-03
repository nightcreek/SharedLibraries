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

    func testConfigurableFormulaDisplayViewInitializerCompiles() {
        let style = FormulaDisplayStyle.default
        let options = FormulaDisplayOptions(debugFramesEnabled: true, cursorVisible: false)
        let metrics = FormulaLayoutMetrics.default
        let type = FormulaDisplayView(
            rawValue: #"\frac{x}{\cursor{}\placeholder{}}"#,
            style: style,
            options: options,
            metrics: metrics
        )
        XCTAssertNotNil(type)
    }

    func testSwiftUITargetUsesCoreSurfaceForPlanConstruction() {
        let markup = FormulaDisplayMarkup(rawValue: "x+1")
        let plan = FormulaDisplayEngine().getPlan(from: markup)
        let factory: @MainActor (FormulaRenderPlan) -> FormulaDisplayView = FormulaDisplayView.init(plan:)
        let type = factory(plan)
        XCTAssertNotNil(type)
    }

    func testCursorHiddenPlanInitializerCompiles() {
        let plan = FormulaDisplayEngine().getPlan(from: FormulaDisplayMarkup(rawValue: #"\cursor{}"#))
        let type = FormulaDisplayView(
            plan: plan,
            style: .default,
            showsCursor: false,
            showsDebugFrames: false
        )
        XCTAssertNotNil(type)
    }

    func testDebugModePlanInitializerCompiles() {
        let debugPlan = FormulaDisplayEngine(
            options: .init(debugFramesEnabled: true, cursorVisible: true),
            metrics: .default
        ).getPlan(from: "x+1")
        let type = FormulaDisplayView(
            plan: debugPlan,
            style: .default,
            showsCursor: true,
            showsDebugFrames: true
        )
        XCTAssertNotNil(type)
    }
}
