import SwiftUI
import XCTest
@testable import EMathicaFormulaDisplayCore
@testable import EMathicaFormulaDisplaySwiftUI

@MainActor
final class FormulaCursorOverlayTests: XCTestCase {
    func testCursorOverlayComputesVisibleRectFromAnchor() {
        let state = FormulaCursorState(
            insertionPoint: .init(
                rect: .init(origin: .init(x: 12, y: 6), size: .init(width: 0, height: 20)),
                baseline: 18
            )
        )

        let rect = FormulaCursorOverlay.cursorRect(for: state)

        XCTAssertEqual(rect.origin.x, 12, accuracy: 0.001)
        XCTAssertEqual(rect.origin.y, 6, accuracy: 0.001)
        XCTAssertEqual(rect.width, 1, accuracy: 0.001)
        XCTAssertEqual(rect.height, 20, accuracy: 0.001)
        XCTAssertEqual(state.insertionPoint.x, 12, accuracy: 0.001)
        XCTAssertEqual(state.insertionPoint.ascent, 8, accuracy: 0.001)
        XCTAssertEqual(state.insertionPoint.descent, 12, accuracy: 0.001)
    }

    func testBlinkControllerStartsVisibleAndThenHides() {
        let reference = Date(timeIntervalSinceReferenceDate: 100)
        let controller = FormulaCursorBlinkController(
            referenceDate: reference,
            visibleDuration: 0.5,
            hiddenDuration: 0.5,
            sampleInterval: 0.1
        )

        XCTAssertTrue(controller.isVisible(at: reference))
        XCTAssertEqual(controller.opacity(at: reference), 1, accuracy: 0.001)
        XCTAssertFalse(controller.isVisible(at: reference.addingTimeInterval(0.75)))
        XCTAssertEqual(controller.opacity(at: reference.addingTimeInterval(0.75)), 0, accuracy: 0.001)
    }

    func testSnapshotViewDerivesSingleCursorStateFromSnapshotAnchor() {
        let snapshot = FormulaSwiftMathSnapshot(
            pngData: Data([0x89]),
            size: .init(width: 32, height: 18),
            baseline: 14,
            cursorAnchor: .init(
                rect: .init(origin: .init(x: 11, y: 2), size: .init(width: 1, height: 15)),
                baseline: 14
            )
        )

        let state = FormulaSwiftMathSnapshotView.cursorState(from: snapshot)

        XCTAssertNotNil(state)
        XCTAssertEqual(state?.insertionPoint, snapshot.cursorAnchor)
        XCTAssertNil(state!.selectionEnd)
    }

    func testSnapshotFrameSizeDependsOnlyOnSnapshotBounds() {
        let snapshot = FormulaSwiftMathSnapshot(
            pngData: Data(),
            size: .init(width: 40, height: 22),
            baseline: 16,
            cursorAnchor: .init(
                rect: .init(origin: .init(x: 18, y: 3), size: .init(width: 1, height: 17)),
                baseline: 16
            )
        )

        let size = FormulaSwiftMathSnapshotView.frameSize(for: snapshot)

        XCTAssertEqual(size.width, 40, accuracy: 0.001)
        XCTAssertEqual(size.height, 22, accuracy: 0.001)
    }

    func testFormulaDisplayViewCompilesWithSwiftMathCursorOverlayEnabled() {
        let view = FormulaDisplayView(
            markup: .init(rawValue: #"x+\cursor{}+y"#),
            style: .default,
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: true,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .init(baseFontSize: 22)
        )

        XCTAssertNotNil(view)
    }
}
