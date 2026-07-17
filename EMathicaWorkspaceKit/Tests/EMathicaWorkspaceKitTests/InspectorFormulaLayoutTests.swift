import EMathicaFormulaDisplayCore
import XCTest
@testable import EMathicaWorkspaceKit

final class InspectorFormulaLayoutTests: XCTestCase {
    func testInspectorXSuperscriptHasNonZeroSize() {
        assertInspectorMeasurementSuccess(for: #"x^3"#)
    }

    func testInspectorFractionHasNonZeroSize() {
        assertInspectorMeasurementSuccess(for: #"\frac{x+1}{x-1}"#)
    }

    func testInspectorSqrtHasNonZeroSize() {
        assertInspectorMeasurementSuccess(for: #"\sqrt{\frac{a+b}{c+d}}"#)
    }

    func testInspectorLongFormulaHasNonZeroSize() {
        assertInspectorMeasurementSuccess(for: #"\sum_{k=1}^{n}\frac{k^2+1}{k^3+2k+1}"#)
    }

    func testInspectorMatrixHasNonZeroSize() {
        assertInspectorMeasurementSuccess(for: #"\begin{pmatrix}1 & -2 \\ 3 & 4\end{pmatrix}"#)
    }

    func testInspectorEmptyFormulaFallsBackToPlainText() {
        let resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .inspector,
            rawValue: "",
            fallbackText: "",
            fontSize: 13,
            minHeight: 20,
            allowsMultiline: true,
            configuration: .default
        )

        guard case .plainText(let text, let reason) = resolved else {
            return XCTFail("Expected plain text fallback for empty formula")
        }

        XCTAssertEqual(text, "")
        XCTAssertEqual(reason, .emptyOutput)
    }

    private func assertInspectorMeasurementSuccess(for markup: String) {
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .legacy,
                fontRole: .standard
            ),
            metrics: FormulaReadOnlyDisplayResolver.makeMetrics(
                surface: .inspector,
                fontSize: 13,
                minHeight: 20
            )
        )

        switch result {
        case .success(let measurement):
            XCTAssertGreaterThan(measurement.width, 0)
            XCTAssertGreaterThan(measurement.height, 0)
        case .failure(let reason, _):
            XCTFail("Expected measurement success, got \(reason)")
        }
    }
}
