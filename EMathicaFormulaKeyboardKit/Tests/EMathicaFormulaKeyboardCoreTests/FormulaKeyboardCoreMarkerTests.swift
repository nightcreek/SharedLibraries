import XCTest
@testable import EMathicaFormulaKeyboardCore

final class FormulaKeyboardCoreMarkerTests: XCTestCase {
    func testVersionMarkerIsAvailable() {
        XCTAssertEqual(EMathicaFormulaKeyboardCoreMarker.version, "0.1.0-dev")
    }
}
