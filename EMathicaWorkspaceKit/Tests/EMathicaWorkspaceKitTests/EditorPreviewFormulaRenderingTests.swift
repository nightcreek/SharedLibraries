import EMathicaFormulaDisplayCore
import XCTest
@testable import EMathicaWorkspaceKit

final class EditorPreviewFormulaRenderingTests: XCTestCase {
    func testEditorPreviewSuperscriptHasNonZeroSize() {
        assertEditorPreviewMeasurementSuccess(for: #"x^2"#)
    }

    func testEditorPreviewFractionHasNonZeroSize() {
        assertEditorPreviewMeasurementSuccess(for: #"\frac{x+1}{x-1}"#)
    }

    func testEditorPreviewSqrtHasNonZeroSize() {
        assertEditorPreviewMeasurementSuccess(for: #"\sqrt{x^2+1}"#)
    }

    func testEditorPreviewMatrixHasNonZeroSize() {
        assertEditorPreviewMeasurementSuccess(for: #"\begin{pmatrix}1&2\\3&4\end{pmatrix}"#)
    }

    func testEditorPreviewUnsupportedSwiftMathMarkupFallsBackToLegacyFormula() {
        let resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .editorPreview,
            rawValue: #"\mathscr{L}"#,
            fallbackText: #"\mathscr{L}"#,
            fontSize: 22,
            minHeight: 44,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, let options, let fallbackReason) = resolved else {
            return XCTFail("Expected legacy formula fallback")
        }

        XCTAssertEqual(options.renderingBackend, .legacy)
        XCTAssertEqual(fallbackReason, .unsupportedCommand)
    }

    private func assertEditorPreviewMeasurementSuccess(for markup: String) {
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .legacy,
                fontRole: .standard
            ),
            metrics: FormulaReadOnlyDisplayResolver.makeMetrics(
                surface: .editorPreview,
                fontSize: 22,
                minHeight: 44
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
