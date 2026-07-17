import SwiftUI
import XCTest
@testable import EMathicaFormulaDisplaySwiftUI
import EMathicaFormulaDisplayCore

@MainActor
final class FormulaRenderPlanViewTests: XCTestCase {
    func testFormulaRenderPlanViewCanInitialize() {
        let plan = FormulaDisplayEngine().getPlan(from: "x+1")
        let view = FormulaRenderPlanView(plan: plan)
        XCTAssertNotNil(view)
    }

    func testCursorVisibilityFalsePathCompiles() {
        let plan = FormulaDisplayEngine().getPlan(from: #"\cursor{}\placeholder{}"#)
        let view = FormulaRenderPlanView(
            plan: plan,
            style: .default,
            showsCursor: false,
            showsDebugFrames: false
        )
        XCTAssertNotNil(view)
    }

    func testDebugModePathCompiles() {
        let plan = FormulaDisplayEngine(
            options: .init(debugFramesEnabled: true, cursorVisible: true),
            metrics: .default
        ).getPlan(from: #"\sqrt{x}"#)
        let view = FormulaRenderPlanView(
            plan: plan,
            style: .default,
            showsCursor: true,
            showsDebugFrames: true
        )
        XCTAssertNotNil(view)
    }

    func testElementHandlingCompilesForSamplePlan() {
        let plan = FormulaRenderPlan(
            size: .init(width: 120, height: 60),
            baseline: 30,
            elements: [
                .text(.init(id: .init("text"), text: "x", fontRole: .normal, frame: .init(origin: .init(x: 4, y: 12), size: .init(width: 12, height: 18)))),
                .line(.init(id: .init("fraction"), frame: .init(origin: .init(x: 20, y: 30), size: .init(width: 40, height: 1)), role: .fractionLine)),
                .radical(.init(
                    id: .init("sqrt"),
                    frame: .init(origin: .init(x: 64, y: 8), size: .init(width: 36, height: 24)),
                    checkStart: .init(x: 66, y: 24),
                    checkBottom: .init(x: 71, y: 30),
                    valley: .init(x: 78, y: 17),
                    shoulder: .init(x: 84, y: 10),
                    overlineStart: .init(x: 88, y: 10),
                    overlineEnd: .init(x: 98, y: 10),
                    role: .radical
                )),
                .cursor(.init(id: .init("cursor"), frame: .init(origin: .init(x: 102, y: 10), size: .init(width: 2, height: 24)))),
                .placeholder(.init(id: .init("placeholder"), frame: .init(origin: .init(x: 108, y: 12), size: .init(width: 12, height: 18))))
            ],
            bounds: .init(origin: .zero, size: .init(width: 120, height: 60)),
            cursorRects: [.init(origin: .init(x: 102, y: 10), size: .init(width: 2, height: 24))],
            placeholderRects: [.init(origin: .init(x: 108, y: 12), size: .init(width: 12, height: 18))],
            hitRegions: [],
            rootNode: .sequence([.text("x", role: .symbol)]),
            rootLayoutBox: nil
        )

        let view = FormulaRenderPlanView(plan: plan, style: .default)
        XCTAssertNotNil(view)
    }

    func testSwiftUITargetStillOnlyNeedsCoreSurface() {
        let style = FormulaDisplayStyle.default
        XCTAssertNotNil(style)
    }
}
