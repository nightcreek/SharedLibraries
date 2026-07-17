import EMathicaFormulaDisplayCore
import XCTest
@testable import EMathicaWorkspaceKit

final class ObjectPanelFormulaFallbackTests: XCTestCase {
    func testMathscrStaysOnSwiftMathPathAndReportsUnsupportedCommand() {
        let resolved = ObjectPanelFormulaDisplayResolver.resolveUncached(
            rawValue: #"\mathscr{L}"#,
            fallbackText: "L",
            fontSize: 13,
            minHeight: 24,
            allowsMultiline: false,
            configuration: .init(backend: .swiftMath, fontRole: .standard)
        )

        guard case .formula(_, _, let options, let reason) = resolved else {
            return XCTFail("Expected SwiftMath diagnostic formula result")
        }
        XCTAssertEqual(options.renderingBackend, .swiftMath)
        XCTAssertEqual(reason, .unsupportedCommand)
    }

    func testMissingBraceMapsToParserFallbackReason() {
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: #"\frac{x}{2"#),
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: ObjectPanelFormulaDisplayResolver.makeMetrics(fontSize: 14, minHeight: 24)
        )

        guard case .failure(let reason, _) = result else {
            return XCTFail("Expected failure")
        }
        XCTAssertEqual(reason, .parserError)
    }

    func testUnclosedEnvironmentMapsToParserFallbackReason() {
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: #"\begin{pmatrix}1 & 2"#),
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: ObjectPanelFormulaDisplayResolver.makeMetrics(fontSize: 14, minHeight: 24)
        )

        guard case .failure(let reason, _) = result else {
            return XCTFail("Expected failure")
        }
        XCTAssertEqual(reason, .parserError)
    }

    func testInvalidCommandMapsToUnsupportedFallbackReason() {
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: #"\unknowncommand{x}"#),
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: ObjectPanelFormulaDisplayResolver.makeMetrics(fontSize: 14, minHeight: 24)
        )

        guard case .failure(let reason, _) = result else {
            return XCTFail("Expected failure")
        }
        XCTAssertEqual(reason, .unsupportedCommand)
    }

    func testEmptyStringFallsBackToPlainTextWhenNoMarkupExists() {
        let resolved = ObjectPanelFormulaDisplayResolver.resolveUncached(
            rawValue: "",
            fallbackText: "",
            fontSize: 13,
            minHeight: 24,
            allowsMultiline: false,
            configuration: .init(backend: .legacy, fontRole: .standard)
        )

        guard case .plainText(_, let reason) = resolved else {
            return XCTFail("Expected plain text fallback")
        }
        XCTAssertEqual(reason, .emptyOutput)
    }
}
