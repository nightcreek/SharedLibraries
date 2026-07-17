import XCTest
@testable import EMathicaFormulaDisplayCore

final class SwiftMathCursorLayoutTests: XCTestCase {
    func testSwiftMathSnapshotIncludesCursorAnchor() {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: #"x+\cursor{}1"#),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved else {
            return XCTFail("Expected SwiftMath snapshot.")
        }

        XCTAssertNotNil(snapshot.cursorAnchor)
        XCTAssertGreaterThan(snapshot.cursorAnchor?.rect.size.height ?? 0, 0)
        XCTAssertGreaterThanOrEqual(snapshot.cursorAnchor?.baseline ?? -1, 0)
    }
}
