import XCTest
@testable import EMathicaFormulaKeyboardSwiftUI

final class FormulaKeyboardSwiftUIMarkerTests: XCTestCase {
    func testVersionMarkerIsAvailable() {
        XCTAssertEqual(EMathicaFormulaKeyboardSwiftUIMarker.version, "0.1.0-dev")
    }
}
