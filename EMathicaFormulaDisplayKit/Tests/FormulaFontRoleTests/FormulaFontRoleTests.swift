import XCTest
@testable import EMathicaFormulaDisplayCore

final class FormulaFontRoleTests: XCTestCase {
    func testDefaultRenderingConfigurationPrefersLegacyAndStandardFontRole() {
        XCTAssertEqual(FormulaDisplayOptions.default.renderingBackend, .legacy)
        XCTAssertEqual(FormulaDisplayOptions.default.fontRole, .standard)
    }

    func testRenderingConfigurationStoresExplicitBackendAndRole() {
        let options = FormulaDisplayOptions(
            debugFramesEnabled: true,
            cursorVisible: false,
            renderingBackend: .swiftMath,
            fontRole: .decorative
        )

        XCTAssertEqual(options.renderingBackend, .swiftMath)
        XCTAssertEqual(options.fontRole, .decorative)
        XCTAssertTrue(options.debugFramesEnabled)
        XCTAssertFalse(options.cursorVisible)
    }
}
