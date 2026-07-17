import EMathicaFormulaDisplayCore
import XCTest
@testable import EMathicaWorkspaceKit

final class ObjectPanelFormulaFontRoleTests: XCTestCase {
    func testObjectPanelDefaultsToStandardRole() {
        XCTAssertEqual(ObjectPanelFormulaDisplayConfiguration.default.fontRole, .standard)
    }

    func testAllFontRolesCanRenderReadOnlyFormula() {
        for role in [FormulaFontRole.standard, .handwrittenResult, .decorative] {
            let result = FormulaReadOnlyRenderProbe.measure(
                markup: .init(rawValue: #"\frac{x^2+1}{\sqrt{2}}"#),
                options: .init(
                    debugFramesEnabled: false,
                    cursorVisible: false,
                    renderingBackend: .swiftMath,
                    fontRole: role
                ),
                metrics: ObjectPanelFormulaDisplayResolver.makeMetrics(fontSize: 14, minHeight: 24)
            )

            guard case .success(let measurement) = result else {
                return XCTFail("Expected render success for font role \(role)")
            }
            XCTAssertGreaterThan(measurement.width, 0)
            XCTAssertGreaterThan(measurement.height, 0)
        }
    }
}
