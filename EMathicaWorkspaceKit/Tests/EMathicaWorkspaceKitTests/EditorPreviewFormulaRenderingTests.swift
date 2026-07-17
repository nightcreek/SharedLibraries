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

    func testEditorPreviewNestedStructureHasNonZeroSize() {
        assertEditorPreviewMeasurementSuccess(for: #"\frac{\sqrt{x^2+1}}{a+b}"#)
    }

    func testEditorPreviewMatrixHasNonZeroSize() {
        assertEditorPreviewMeasurementSuccess(for: #"\begin{pmatrix}1&2\\3&4\end{pmatrix}"#)
    }

    func testEditorPreviewDocumentPathHasNonZeroSize() {
        assertEditorPreviewDocumentMeasurementSuccess(for: #"\frac{\sqrt{x^2+1}}{a+b}"#)
    }

    func testEditorPreviewUnsupportedSwiftMathMarkupReturnsDiagnosticFormulaResult() {
        let resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .editorPreview,
            rawValue: #"\mathscr{L}"#,
            fallbackText: #"\mathscr{L}"#,
            fontSize: 22,
            minHeight: 44,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, _, let options, let fallbackReason) = resolved else {
            return XCTFail("Expected SwiftMath diagnostic formula result")
        }

        XCTAssertEqual(options.renderingBackend, .swiftMath)
        XCTAssertEqual(fallbackReason, .unsupportedCommand)
    }

    func testEditorPreviewPlainTextSanitizerRemovesInternalCursorCommand() {
        XCTAssertEqual(
            FormulaReadOnlyDisplayResolver.sanitizePlainText(#"\cursor{}("#),
            "("
        )
    }

    func testEditorPreviewLongPlainFormulaStaysOnFormulaPath() {
        let resolved = FormulaReadOnlyDisplayResolver.resolveUncached(
            surface: .editorPreview,
            rawValue: "abcdefghi",
            fallbackText: "abcdefghi",
            fontSize: 22,
            minHeight: 44,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, _, let options, _) = resolved else {
            return XCTFail("Expected formula rendering path")
        }

        XCTAssertEqual(options.renderingBackend, .swiftMath)
    }

    private func assertEditorPreviewMeasurementSuccess(for markup: String) {
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .swiftMath,
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

    private func assertEditorPreviewDocumentMeasurementSuccess(for documentMarkup: String) {
        let document = FormulaDisplayDocument(
            root: FormulaDisplayNode.sequence([.raw(documentMarkup)])
        )
        let result = FormulaReadOnlyRenderProbe.measure(
            document: document,
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .swiftMath,
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
            XCTFail("Expected document measurement success, got \(reason)")
        }
    }
}
