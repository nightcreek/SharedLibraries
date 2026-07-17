import XCTest
import EMathicaFormulaDisplayCore
import SwiftUI
@testable import EMathicaFormulaDisplaySwiftUI

@MainActor
final class FormulaInsertionHitResolverTests: XCTestCase {
    func testResolverReturnsNilWhenNoAnchorsExist() {
        let layout = makeLayout()

        XCTAssertNil(
            FormulaInsertionHitResolver.resolve(
                at: CGPoint(x: 12, y: 12),
                layout: layout,
                insertionAnchors: [],
                placeholderAnchors: []
            )
        )
    }

    func testResolverHonorsCanvasCoordinatesWithoutDoubleApplyingContentOrigin() {
        let layout = makeLayout(
            contentOrigin: CGPoint(x: 14, y: 18),
            canvasSize: CGSize(width: 80, height: 60),
            formulaFrame: CGRect(x: 14, y: 18, width: 20, height: 16)
        )
        let anchor = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]"],
                offset: 1,
                affinity: .interior
            ),
            rect: CGRect(x: 6, y: 5, width: 0, height: 10),
            x: 6,
            baseline: 10,
            ascent: 5,
            descent: 5,
            offset: 1,
            sourcePath: ["sequence[0]"],
            fieldIdentity: nil
        )

        XCTAssertEqual(
            FormulaInsertionHitResolver.resolve(
                at: CGPoint(x: 20, y: 24),
                layout: layout,
                insertionAnchors: [anchor],
                placeholderAnchors: []
            ),
            anchor.id
        )
    }

    func testPlaceholderExactHitPrefersMatchingFieldInsertionAnchor() {
        let placeholder = makePlaceholderAnchor(
            id: "placeholder:sequence[0]/field.radicand",
            rect: CGRect(x: 8, y: 6, width: 14, height: 12),
            baseline: 14,
            ascent: 6,
            descent: 6,
            context: .radicalRadicand,
            sourcePath: ["sequence[0]", "field.radicand"],
            fieldIdentity: "radicand",
            kind: "radicand"
        )
        let layout = makeLayout(
            placeholderAnchors: [placeholder],
            placeholderRects: [
                FormulaPlaceholderOverlay.overlayRect(for: placeholder)
            ]
        )
        let leading = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]", "field.radicand"],
                offset: 0,
                affinity: .leading
            ),
            rect: CGRect(x: 9, y: 7, width: 0, height: 10),
            x: 9,
            baseline: 14,
            ascent: 6,
            descent: 6,
            offset: 0,
            sourcePath: ["sequence[0]", "field.radicand"],
            fieldIdentity: "radicand"
        )
        let trailing = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]", "field.radicand"],
                offset: 1,
                affinity: .trailing
            ),
            rect: CGRect(x: 19, y: 7, width: 0, height: 10),
            x: 19,
            baseline: 14,
            ascent: 6,
            descent: 6,
            offset: 1,
            sourcePath: ["sequence[0]", "field.radicand"],
            fieldIdentity: "radicand"
        )

        let hit = FormulaInsertionHitResolver.resolve(
            at: CGPoint(x: 14, y: 11),
            layout: layout,
            insertionAnchors: [leading, trailing],
            placeholderAnchors: [placeholder]
        )

        XCTAssertEqual(hit, leading.id)
    }

    func testResolverKeepsNumeratorAndDenominatorSeparatedByVerticalDistance() {
        let layout = makeLayout()
        let numerator = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]", "field.numerator"],
                offset: 0,
                affinity: .leading
            ),
            rect: CGRect(x: 12, y: 5, width: 0, height: 10),
            x: 12,
            baseline: 10,
            ascent: 5,
            descent: 5,
            offset: 0,
            sourcePath: ["sequence[0]", "field.numerator"],
            fieldIdentity: "numerator"
        )
        let denominator = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]", "field.denominator"],
                offset: 0,
                affinity: .leading
            ),
            rect: CGRect(x: 15, y: 30, width: 0, height: 10),
            x: 15,
            baseline: 35,
            ascent: 5,
            descent: 5,
            offset: 0,
            sourcePath: ["sequence[0]", "field.denominator"],
            fieldIdentity: "denominator"
        )

        let hit = FormulaInsertionHitResolver.resolve(
            at: CGPoint(x: 14, y: 8),
            layout: layout,
            insertionAnchors: [numerator, denominator],
            placeholderAnchors: []
        )

        XCTAssertEqual(hit, numerator.id)
    }

    func testResolverChoosesNearestAnchorWithinSamePath() {
        let layout = makeLayout()
        let left = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]"],
                offset: 0,
                affinity: .leading
            ),
            rect: CGRect(x: 8, y: 12, width: 0, height: 10),
            x: 8,
            baseline: 17,
            ascent: 5,
            descent: 5,
            offset: 0,
            sourcePath: ["sequence[0]"],
            fieldIdentity: nil
        )
        let right = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]"],
                offset: 1,
                affinity: .trailing
            ),
            rect: CGRect(x: 24, y: 12, width: 0, height: 10),
            x: 24,
            baseline: 17,
            ascent: 5,
            descent: 5,
            offset: 1,
            sourcePath: ["sequence[0]"],
            fieldIdentity: nil
        )

        let hit = FormulaInsertionHitResolver.resolve(
            at: CGPoint(x: 22, y: 16),
            layout: layout,
            insertionAnchors: [left, right],
            placeholderAnchors: []
        )

        XCTAssertEqual(hit, right.id)
    }

    func testResolverKeepsMatrixLikeCellsIsolatedBySourcePath() {
        let layout = makeLayout()
        let topCell = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]", "field.matrixCell[0,0]"],
                offset: 0,
                affinity: .leading
            ),
            rect: CGRect(x: 10, y: 8, width: 0, height: 10),
            x: 10,
            baseline: 13,
            ascent: 5,
            descent: 5,
            offset: 0,
            sourcePath: ["sequence[0]", "field.matrixCell[0,0]"],
            fieldIdentity: "matrixCell[0,0]"
        )
        let bottomCell = makeInsertionAnchor(
            id: FormulaInsertionID(
                sourcePath: ["sequence[0]", "field.matrixCell[1,0]"],
                offset: 0,
                affinity: .leading
            ),
            rect: CGRect(x: 12, y: 26, width: 0, height: 10),
            x: 12,
            baseline: 31,
            ascent: 5,
            descent: 5,
            offset: 0,
            sourcePath: ["sequence[0]", "field.matrixCell[1,0]"],
            fieldIdentity: "matrixCell[1,0]"
        )

        let hit = FormulaInsertionHitResolver.resolve(
            at: CGPoint(x: 11, y: 12),
            layout: layout,
            insertionAnchors: [topCell, bottomCell],
            placeholderAnchors: []
        )

        XCTAssertEqual(hit, topCell.id)
    }

    private func makeLayout(
        contentOrigin: CGPoint = .zero,
        canvasSize: CGSize = CGSize(width: 60, height: 40),
        formulaFrame: CGRect = CGRect(x: 0, y: 0, width: 20, height: 16),
        placeholderAnchors: [FormulaPlaceholderAnchor] = [],
        placeholderRects: [CGRect] = []
    ) -> FormulaEditorCanvasLayout {
        FormulaEditorCanvasLayout(
            snapshotSize: CGSize(width: 20, height: 16),
            contentInsets: .init(),
            contentOrigin: contentOrigin,
            canvasSize: canvasSize,
            formulaFrame: formulaFrame,
            cursorAnchor: nil,
            cursorVisualRect: nil,
            placeholderAnchors: placeholderAnchors,
            placeholderRects: placeholderRects
        )
    }

    private func makeInsertionAnchor(
        id: FormulaInsertionID,
        rect: CGRect,
        x: CGFloat,
        baseline: CGFloat,
        ascent: CGFloat,
        descent: CGFloat,
        offset: Int,
        sourcePath: [String],
        fieldIdentity: String?
    ) -> FormulaInsertionAnchor {
        FormulaInsertionAnchor(
            id: id,
            rect: .init(origin: .init(x: rect.origin.x, y: rect.origin.y), size: .init(width: rect.size.width, height: rect.size.height)),
            x: x,
            baseline: baseline,
            ascent: ascent,
            descent: descent,
            offset: offset,
            affinity: id.affinity,
            sourcePath: sourcePath,
            fieldIdentity: fieldIdentity
        )
    }

    private func makePlaceholderAnchor(
        id: String,
        rect: CGRect,
        baseline: CGFloat,
        ascent: CGFloat,
        descent: CGFloat,
        context: FormulaCursorContext,
        sourcePath: [String],
        fieldIdentity: String?,
        kind: String
    ) -> FormulaPlaceholderAnchor {
        FormulaPlaceholderAnchor(
            id: id,
            rect: .init(origin: .init(x: rect.origin.x, y: rect.origin.y), size: .init(width: rect.size.width, height: rect.size.height)),
            baseline: baseline,
            ascent: ascent,
            descent: descent,
            context: context,
            sourcePath: sourcePath,
            fieldIdentity: fieldIdentity,
            kind: kind,
            widthPolicy: .quad
        )
    }
}
