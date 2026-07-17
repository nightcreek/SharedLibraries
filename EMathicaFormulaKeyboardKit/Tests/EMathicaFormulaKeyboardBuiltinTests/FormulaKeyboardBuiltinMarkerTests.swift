import XCTest
@testable import EMathicaFormulaKeyboardBuiltin

final class FormulaKeyboardBuiltinMarkerTests: XCTestCase {
    func testVersionMarkerIsAvailable() {
        XCTAssertEqual(EMathicaFormulaKeyboardBuiltinMarker.version, "0.1.0-dev")
    }
}
