import XCTest
@testable import EMathicaFormulaDisplayCore

final class SwiftMathCursorGeometryTests: XCTestCase {
    func testCursorAnchorExistsForInlineFormula() {
        let anchor = assertCursorAnchor(for: #"x+\cursor{}+y"#)
        XCTAssertEqual(anchor.context, .inline)
    }

    func testCursorAnchorExistsInsideFraction() {
        let anchor = assertCursorAnchor(for: #"\frac{x+\cursor{}}{y}"#)
        XCTAssertEqual(anchor.context, .numerator)
    }

    func testCursorAnchorExistsInsideRadical() {
        let anchor = assertCursorAnchor(for: #"\sqrt{x+\cursor{}}"#)
        XCTAssertEqual(anchor.context, .radicalRadicand)
    }

    func testCursorAnchorExistsInsideSuperscript() {
        let anchor = assertCursorAnchor(for: #"x^{\cursor{}}"#)
        XCTAssertEqual(anchor.context, .superscript)
    }

    func testCursorPlaceholderDoesNotBlowUpRadicalOrFractionHeight() {
        let baseSqrt = measureSnapshot(for: #"\sqrt{x+y}"#)
        let cursorSqrt = measureSnapshot(for: #"\sqrt{x+\cursor{}+y}"#)
        XCTAssertLessThanOrEqual(cursorSqrt.size.height - baseSqrt.size.height, 6)

        let baseFraction = measureSnapshot(for: #"\frac{\sqrt{x+y}}{y}"#)
        let cursorFraction = measureSnapshot(for: #"\frac{\sqrt{x+\cursor{}+y}}{y}"#)
        XCTAssertLessThanOrEqual(cursorFraction.size.height - baseFraction.size.height, 6)
    }

    @discardableResult
    private func assertCursorAnchor(for markup: String) -> FormulaCursorAnchor {
        let snapshot = measureSnapshot(for: markup)

        guard let anchor = snapshot.cursorAnchor else {
            XCTFail("Expected cursor anchor for \(markup)")
            fatalError("Missing cursor anchor")
        }

        XCTAssertGreaterThan(anchor.rect.size.width, 0, "Expected positive cursor width for \(markup)")
        XCTAssertGreaterThan(anchor.rect.size.height, 0, "Expected positive cursor height for \(markup)")
        XCTAssertGreaterThan(anchor.ascent, 0, "Expected positive cursor ascent for \(markup)")
        XCTAssertGreaterThanOrEqual(anchor.descent, 0, "Expected non-negative cursor descent for \(markup)")
        XCTAssertGreaterThanOrEqual(anchor.baseline, 0, "Expected non-negative baseline for \(markup)")
        return anchor
    }

    private func measureSnapshot(for markup: String) -> FormulaSwiftMathSnapshot {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: true,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved else {
            XCTFail("Expected SwiftMath snapshot for \(markup)")
            fatalError("Missing SwiftMath snapshot")
        }
        return snapshot
    }
}
