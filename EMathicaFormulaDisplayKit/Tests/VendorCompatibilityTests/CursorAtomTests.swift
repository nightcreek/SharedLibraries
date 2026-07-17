import XCTest
@testable import EMathicaFormulaDisplayVendor

final class CursorAtomTests: XCTestCase {
    func testCursorCommandBuildsCursorAtom() {
        var error: NSError?
        let mathList = MTMathListBuilder.build(fromString: #"x+\cursor{}"#, error: &error)

        XCTAssertNil(error)
        XCTAssertNotNil(mathList)
        XCTAssertTrue(containsCursor(in: mathList))
    }

    func testCursorCommandBuildsNestedCursorAtom() {
        let formulas = [
            #"\frac{x+\cursor{}}{y}"#,
            #"\sqrt{x+\cursor{}}"#
        ]

        for formula in formulas {
            var error: NSError?
            let mathList = MTMathListBuilder.build(fromString: formula, error: &error)

            XCTAssertNil(error, "Unexpected parse error for \(formula): \(String(describing: error))")
            XCTAssertTrue(containsCursor(in: mathList), "Expected nested cursor atom in \(formula)")
        }
    }

    func testSwiftMathRendererExportsCursorAnchorWithReservedPlaceholderAdvance() {
        let base = SwiftMathReadOnlyRenderer.renderPNG(
            latex: "x+1",
            fontRole: .standard,
            fontSize: 24,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
            displayStyle: .display
        )
        let withCursor = SwiftMathReadOnlyRenderer.renderPNG(
            latex: #"x+\cursor{}1"#,
            fontRole: .standard,
            fontSize: 24,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
            displayStyle: .display
        )

        guard case .success(let baseImage) = base else {
            return XCTFail("Expected base SwiftMath render success.")
        }
        guard case .success(let cursorImage) = withCursor else {
            return XCTFail("Expected cursor SwiftMath render success.")
        }

        XCTAssertNotNil(cursorImage.cursorAnchor)
        XCTAssertGreaterThan(cursorImage.size.width, baseImage.size.width)
        XCTAssertGreaterThan(cursorImage.size.height, 0)
        XCTAssertGreaterThan(cursorImage.cursorAnchor?.rect.height ?? 0, 0)
        XCTAssertGreaterThanOrEqual(cursorImage.cursorAnchor?.baseline ?? -1, 0)
    }

    private func containsCursor(in mathList: MTMathList?) -> Bool {
        guard let mathList else { return false }
        for atom in mathList.atoms {
            if atom.type == .cursor {
                return true
            }
            if let fraction = atom as? MTFraction {
                if containsCursor(in: fraction.numerator) || containsCursor(in: fraction.denominator) {
                    return true
                }
            }
            if let radical = atom as? MTRadical {
                if containsCursor(in: radical.radicand) || containsCursor(in: radical.degree) {
                    return true
                }
            }
            if let inner = atom as? MTInner, containsCursor(in: inner.innerList) {
                return true
            }
        }
        return false
    }
}
