import XCTest
@testable import EMathicaFormulaDisplayVendor

final class SwiftMathVendorCompatibilityTests: XCTestCase {
    func testPinnedReadOnlyRendererSupportsPhaseOneFormulaSet() {
        let formulas = [
            #"\frac{-b \pm \sqrt{b^2-4ac}}{2a}"#,
            #"\dfrac{1}{1+\sqrt{2}}"#,
            #"\sqrt[3]{1+\sqrt{x}}"#,
            #"x_{i}^{2}"#,
            #"\begin{cases}x^2, & x \ge 0\\-x, & x < 0\end{cases}"#,
            #"\begin{aligned}(a+b)^2&=a^2+2ab+b^2\\(a-b)^2&=a^2-2ab+b^2\end{aligned}"#,
            #"\begin{pmatrix}1 & -2\\3 & 4\end{pmatrix}"#,
            #"\begin{bmatrix}a & b\\c & d\end{bmatrix}"#,
            #"\begin{pmatrix*}[r]1 & -2\\3 & 4\end{pmatrix*}"#,
            #"\left(\begin{smallmatrix}a & b\\c & d\end{smallmatrix}\right)"#
        ]

        for role in [SwiftMathFontRole.standard, .handwrittenResult, .decorative] {
            for formula in formulas {
                switch SwiftMathReadOnlyRenderer.renderPNG(
                    latex: formula,
                    fontRole: role,
                    fontSize: 24,
                    foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
                    displayStyle: .display
                ) {
                case .success(let image):
                    XCTAssertFalse(image.pngData.isEmpty)
                    XCTAssertGreaterThan(image.size.width, 0)
                    XCTAssertGreaterThan(image.size.height, 0)
                    XCTAssertGreaterThanOrEqual(image.baseline, 0)
                case .failure(let error):
                    XCTFail("Expected render success for \(formula) with role \(role), got \(error)")
                }
            }
        }
    }

    func testPinnedFontsLoadAndExposeMathTables() {
        for font in MathFont.allCases {
            let cgFont = font.cgFont()
            let ctFont = font.ctFont(withSize: 24)
            let mtFont = font.mtfont(size: 24)

            XCTAssertGreaterThan(cgFont.numberOfGlyphs, 0)
            XCTAssertGreaterThan(CTFontGetAscent(ctFont), 0)
            XCTAssertNotNil(mtFont.mathTable)
        }
    }

    func testKnownInvalidInputsReturnDiagnosticsInsteadOfCrashing() {
        let invalidFormulas = [
            "",
            #"\unknowncommand{x}"#,
            #"\frac{x}{2"#,
            #"\begin{pmatrix}1 & 2"#,
            #"\mathscr{L}"#
        ]

        for formula in invalidFormulas {
            switch SwiftMathReadOnlyRenderer.renderPNG(
                latex: formula,
                fontRole: .standard,
                fontSize: 24,
                foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1),
                displayStyle: .display
            ) {
            case .success:
                XCTFail("Expected diagnostic failure for \(formula)")
            case .failure(let error):
                XCTAssertFalse(error.message.isEmpty)
            }
        }
    }

    func testLineWrappingPathCanRespectMaxWidthForLongFormula() throws {
        var error: NSError?
        let mathList = MTMathListBuilder.build(
            fromString: #"x_1+x_2+x_3+x_4+x_5+x_6+x_7+x_8+x_9+x_{10}"#,
            error: &error
        )
        XCTAssertNil(error)

        let display = MTTypesetter.createLineForMathList(
            mathList,
            font: MathFont.xitsFont.mtfont(size: 20),
            style: .display,
            maxWidth: 80
        )

        XCTAssertNotNil(display)
        XCTAssertLessThanOrEqual(display?.width ?? .greatestFiniteMagnitude, 110)
        let totalHeight = (display?.ascent ?? 0) + (display?.descent ?? 0)
        XCTAssertGreaterThan(totalHeight, 0)
    }
}
