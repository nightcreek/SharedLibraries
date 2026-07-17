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
        XCTAssertLessThan(rect.origin.y, 6)
        XCTAssertEqual(rect.width, 2, accuracy: 0.001)
        XCTAssertGreaterThan(rect.height, 20)
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
                id: "cursor:root@1",
                rect: .init(origin: .init(x: 11, y: 2), size: .init(width: 1, height: 15)),
                x: 11,
                baseline: 14,
                ascent: 3,
                descent: 12,
                offset: 1,
                context: .inline,
                sourcePath: ["root"],
                fieldIdentity: nil
            )
        )

        let state = FormulaSwiftMathSnapshotView.cursorState(from: snapshot)

        XCTAssertNotNil(state)
        XCTAssertEqual(state?.insertionPoint, snapshot.cursorAnchor)
        XCTAssertEqual(state?.insertionPoint.offset, 1)
        XCTAssertNil(state!.selectionEnd)
    }

    func testSnapshotFrameSizeDependsOnlyOnSnapshotBounds() {
        let snapshot = FormulaSwiftMathSnapshot(
            pngData: Data(),
            size: .init(width: 40, height: 22),
            baseline: 16,
            cursorAnchor: .init(
                id: "cursor:root@2",
                rect: .init(origin: .init(x: 18, y: 3), size: .init(width: 1, height: 17)),
                x: 18,
                baseline: 16,
                ascent: 4,
                descent: 13,
                offset: 2,
                context: .inline,
                sourcePath: ["root"],
                fieldIdentity: nil
            )
        )

        let size = FormulaSwiftMathSnapshotView.imageSize(for: snapshot)

        XCTAssertEqual(size.width, 40, accuracy: 0.001)
        XCTAssertEqual(size.height, 22, accuracy: 0.001)
    }

    func testCanvasLayoutExpandsToContainVisibleCursor() {
        let snapshot = FormulaSwiftMathSnapshot(
            pngData: Data(),
            size: .init(width: 11, height: 15),
            baseline: 8.21,
            cursorAnchor: .init(
                id: "cursor:root@1",
                rect: .init(origin: .init(x: 10, y: 6.34), size: .init(width: 1, height: 8.63)),
                x: 10,
                baseline: 8.21,
                ascent: 6.75,
                descent: 1.88,
                offset: 1,
                context: .superscript,
                sourcePath: ["root"],
                fieldIdentity: nil
            )
        )

        let layout = FormulaSwiftMathSnapshotView.editorCanvasLayout(for: snapshot, showsCursor: true)
        let cursorRect = layout.cursorVisualRect

        XCTAssertNotNil(cursorRect)
        XCTAssertGreaterThan(layout.canvasSize.width, snapshot.size.width)
        XCTAssertGreaterThan(layout.canvasSize.height, snapshot.size.height)
        XCTAssertGreaterThanOrEqual(layout.contentOrigin.x, 0)
        XCTAssertGreaterThanOrEqual(layout.contentOrigin.y, 0)
        XCTAssertEqual(layout.formulaFrame.origin.x, layout.contentOrigin.x, accuracy: 0.001)
        XCTAssertEqual(layout.formulaFrame.origin.y, layout.contentOrigin.y, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(cursorRect!.minX, 0)
        XCTAssertGreaterThanOrEqual(cursorRect!.minY, 0)
        XCTAssertLessThanOrEqual(cursorRect!.maxX, layout.canvasSize.width)
        XCTAssertLessThanOrEqual(cursorRect!.maxY, layout.canvasSize.height)
    }

    func testCanvasLayoutKeepsBaseSizeWhenCursorIsAbsent() {
        let snapshot = FormulaSwiftMathSnapshot(
            pngData: Data(),
            size: .init(width: 40, height: 22),
            baseline: 16,
            cursorAnchor: nil
        )

        let layout = FormulaSwiftMathSnapshotView.editorCanvasLayout(for: snapshot, showsCursor: false)

        XCTAssertEqual(layout.canvasSize.width, 40, accuracy: 0.001)
        XCTAssertEqual(layout.canvasSize.height, 22, accuracy: 0.001)
        XCTAssertEqual(layout.contentOffset.width, 0, accuracy: 0.001)
        XCTAssertEqual(layout.contentOffset.height, 0, accuracy: 0.001)
        XCTAssertNil(layout.cursorVisualRect)
        XCTAssertEqual(layout.placeholderRects.count, 0)
    }

    func testEditorCanvasLayoutContainsRepresentativeCursorContexts() {
        let cases: [(FormulaCursorContext, FormulaRect, FormulaSize, Double, Double, Double)] = [
            (.inline, .init(origin: .init(x: 33.59, y: 1.36), size: .init(width: 1, height: 11.50)), .init(width: 71, height: 15), 3.86, 9.00, 2.50),
            (.superscript, .init(origin: .init(x: 11.00, y: 6.34), size: .init(width: 1, height: 8.63)), .init(width: 11, height: 15), 8.21, 6.75, 1.88),
            (.subscriptField, .init(origin: .init(x: 11.00, y: 0.15), size: .init(width: 1, height: 8.63)), .init(width: 11, height: 16), 2.03, 6.75, 1.88),
            (.numerator, .init(origin: .init(x: 4.96, y: 27.39), size: .init(width: 1, height: 11.50)), .init(width: 10, height: 39), 29.89, 9.00, 2.50),
            (.denominator, .init(origin: .init(x: 5.50, y: 0.04), size: .init(width: 1, height: 11.50)), .init(width: 11, height: 37), 2.54, 9.00, 2.50),
            (.radicalRadicand, .init(origin: .init(x: 52.15, y: 3.10), size: .init(width: 1, height: 11.50)), .init(width: 53, height: 26), 5.60, 9.00, 2.50)
        ]

        for (context, rect, size, baseline, ascent, descent) in cases {
            let snapshot = FormulaSwiftMathSnapshot(
                pngData: Data(),
                size: size,
                baseline: baseline,
                cursorAnchor: .init(
                    id: "cursor:\(context)",
                    rect: .init(
                        origin: .init(x: rect.origin.x, y: rect.origin.y),
                        size: .init(width: rect.size.width, height: rect.size.height)
                    ),
                    x: rect.origin.x,
                    baseline: baseline,
                    ascent: ascent,
                    descent: descent,
                    offset: 1,
                    context: context,
                    sourcePath: ["root"],
                    fieldIdentity: nil
                )
            )

            let layout = FormulaSwiftMathSnapshotView.editorCanvasLayout(for: snapshot, showsCursor: true)
            let cursorRect = layout.cursorVisualRect

            XCTAssertNotNil(cursorRect, "Expected cursor rect for \(context)")
            XCTAssertGreaterThanOrEqual(cursorRect!.minX, 0, "Cursor should stay inside canvas on x for \(context)")
            XCTAssertGreaterThanOrEqual(cursorRect!.minY, 0, "Cursor should stay inside canvas on y for \(context)")
            XCTAssertLessThanOrEqual(cursorRect!.maxX, layout.canvasSize.width, "Cursor should fit canvas width for \(context)")
            XCTAssertLessThanOrEqual(cursorRect!.maxY, layout.canvasSize.height, "Cursor should fit canvas height for \(context)")
            XCTAssertEqual(layout.cursorAnchor?.context, context)
            XCTAssertEqual(layout.placeholderAnchors.count, 0)
        }
    }

    func testEditorCanvasLayoutIncludesPlaceholderOverflow() {
        let snapshot = FormulaSwiftMathSnapshot(
            pngData: Data(),
            size: .init(width: 18, height: 12),
            baseline: 8,
            cursorAnchor: .init(
                id: "cursor:root@0",
                rect: .init(origin: .init(x: 3, y: 2), size: .init(width: 1, height: 8)),
                x: 3,
                baseline: 8,
                ascent: 4,
                descent: 4,
                offset: 0,
                context: .inline,
                sourcePath: ["root"],
                fieldIdentity: nil
            ),
            placeholderAnchors: [
                .init(
                    id: "placeholder:root@0",
                    rect: .init(origin: .init(x: -4, y: -1), size: .init(width: 6, height: 8)),
                    baseline: 6,
                    ascent: 3,
                    descent: 3,
                    context: .inline,
                    sourcePath: ["root"],
                    fieldIdentity: "root",
                    kind: "emptyField",
                    widthPolicy: .quad
                )
            ]
        )

        let layout = FormulaSwiftMathSnapshotView.editorCanvasLayout(for: snapshot, showsCursor: true)

        XCTAssertGreaterThan(layout.canvasSize.width, snapshot.size.width)
        XCTAssertGreaterThan(layout.canvasSize.height, snapshot.size.height)
        XCTAssertEqual(layout.placeholderAnchors.count, 1)
        XCTAssertEqual(layout.placeholderRects.count, 1)
        XCTAssertGreaterThanOrEqual(layout.placeholderRects[0].minX, 0)
        XCTAssertGreaterThanOrEqual(layout.placeholderRects[0].minY, 0)
        XCTAssertLessThanOrEqual(layout.placeholderRects[0].maxX, layout.canvasSize.width)
        XCTAssertLessThanOrEqual(layout.placeholderRects[0].maxY, layout.canvasSize.height)
        XCTAssertLessThanOrEqual(layout.formulaFrame.minX, layout.placeholderRects[0].maxX)
    }

    func testCursorOverlayCentersVisibleStrokeInsideAnchorWidth() {
        let state = FormulaCursorState(
            insertionPoint: .init(
                rect: .init(origin: .init(x: 10, y: 4), size: .init(width: 6, height: 18)),
                x: 10,
                baseline: 14,
                ascent: 8,
                descent: 10,
                offset: 0,
                context: .inline,
                sourcePath: [],
                fieldIdentity: nil
            )
        )

        let rect = FormulaCursorOverlay.cursorRect(for: state)

        XCTAssertGreaterThanOrEqual(rect.minX, 10)
        XCTAssertLessThanOrEqual(rect.maxX, 16)
        XCTAssertLessThanOrEqual(rect.width, 2)
    }

    func testSuperscriptCursorShiftsUpAndGrowsComparedToInline() {
        let inlineRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .inline))
        )
        let superscriptRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .superscript))
        )

        XCTAssertLessThan(superscriptRect.minY, inlineRect.minY)
        XCTAssertGreaterThan(superscriptRect.height, inlineRect.height)
        XCTAssertEqual(superscriptRect.width, 1.5, accuracy: 0.001)
    }

    func testSubscriptCursorShiftsDownAndGrowsComparedToInline() {
        let inlineRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .inline))
        )
        let subscriptRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .subscriptField))
        )

        XCTAssertGreaterThan(subscriptRect.minY, inlineRect.minY)
        XCTAssertGreaterThan(subscriptRect.maxY, inlineRect.maxY)
        XCTAssertGreaterThan(subscriptRect.height, inlineRect.height)
    }

    func testNumeratorAndDenominatorAvoidFractionLineInOppositeDirections() {
        let numeratorRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .numerator))
        )
        let denominatorRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .denominator))
        )

        XCTAssertLessThan(numeratorRect.minY, denominatorRect.minY)
        XCTAssertLessThan(numeratorRect.maxY, denominatorRect.maxY)
    }

    func testRadicalRadicandCursorBiasesAwayFromOverline() {
        let inlineRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .inline))
        )
        let radicalRect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(insertionPoint: makeAnchor(context: .radicalRadicand))
        )

        XCTAssertGreaterThan(radicalRect.minY, inlineRect.minY)
        XCTAssertGreaterThan(radicalRect.height, inlineRect.height - 0.5)
    }

    func testScriptContextKeepsUsefulMinimumHeightForTinyAnchors() {
        let rect = FormulaCursorOverlay.cursorRect(
            for: FormulaCursorState(
                insertionPoint: .init(
                    rect: .init(origin: .init(x: 8, y: 5), size: .init(width: 1, height: 4)),
                    x: 8,
                    baseline: 7,
                    ascent: 1,
                    descent: 3,
                    offset: 0,
                    context: .superscript,
                    sourcePath: [],
                    fieldIdentity: nil
                )
            )
        )

        XCTAssertGreaterThanOrEqual(rect.height, 12)
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

    private func makeAnchor(context: FormulaCursorContext) -> FormulaCursorAnchor {
        .init(
            rect: .init(origin: .init(x: 12, y: 6), size: .init(width: 2, height: 20)),
            x: 12,
            baseline: 18,
            ascent: 8,
            descent: 12,
            offset: 0,
            context: context,
            sourcePath: [],
            fieldIdentity: nil
        )
    }
}
