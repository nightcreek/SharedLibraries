import XCTest
@testable import EMathicaHomeFeature

final class EMathicaHomeFeatureTests: XCTestCase {
    func testPackageName() {
        XCTAssertEqual(EMathicaHomeFeature.packageName, "EMathicaHomeFeature")
    }
}
