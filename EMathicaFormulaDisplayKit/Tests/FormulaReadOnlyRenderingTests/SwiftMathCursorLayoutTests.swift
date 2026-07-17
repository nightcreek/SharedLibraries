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

    func testSwiftMathSnapshotIncludesPassiveInsertionAnchors() {
        let document = FormulaDisplayDocument(
            root: .sequence([
                .insertionMarker(
                    .init(
                        id: .init(sourcePath: ["root"], offset: 0, affinity: .leading),
                        sourcePath: ["root"],
                        offset: 0,
                        affinity: .leading
                    )
                ),
                .text("x", role: .symbol),
                .insertionMarker(
                    .init(
                        id: .init(sourcePath: ["root"], offset: 1, affinity: .trailing),
                        sourcePath: ["root"],
                        offset: 1,
                        affinity: .trailing
                    )
                )
            ])
        )

        let resolved = FormulaDisplayContentResolver.resolve(
            document: document,
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

        let plainResolved = FormulaDisplayContentResolver.resolve(
            document: FormulaDisplayDocument(root: .sequence([.text("x", role: .symbol)])),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let plainSnapshot) = plainResolved else {
            return XCTFail("Expected plain SwiftMath snapshot.")
        }

        XCTAssertNil(snapshot.cursorAnchor)
        XCTAssertEqual(snapshot.insertionAnchors.count, 2)
        XCTAssertTrue(snapshot.insertionAnchors.allSatisfy { $0.rect.size.width <= 0.001 })
        XCTAssertTrue(snapshot.insertionAnchors.allSatisfy { $0.descent >= 0 })
        XCTAssertTrue(snapshot.insertionAnchors.allSatisfy { $0.ascent >= 0 })
        XCTAssertEqual(snapshot.size.width, plainSnapshot.size.width, accuracy: 0.001)
        XCTAssertEqual(snapshot.size.height, plainSnapshot.size.height, accuracy: 0.001)
    }
}
