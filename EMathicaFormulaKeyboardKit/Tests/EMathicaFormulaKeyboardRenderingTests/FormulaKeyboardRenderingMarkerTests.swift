import XCTest
@testable import EMathicaFormulaKeyboardRendering

final class FormulaKeyboardRenderingMarkerTests: XCTestCase {
    func testVersionMarkerIsAvailable() {
        XCTAssertEqual(EMathicaFormulaKeyboardRenderingMarker.version, "0.1.0-dev")
    }
}
