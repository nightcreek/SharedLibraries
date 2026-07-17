import EMathicaFormulaDisplayCore
import XCTest
@testable import EMathicaWorkspaceKit

final class ObjectPanelFormulaLayoutTests: XCTestCase {
    func testProbeReportsFiniteNonZeroMeasurementsForRepresentativeFormulas() {
        let formulas = [
            #"\sqrt{x+1}"#,
            #"\frac{-b \pm \sqrt{b^2-4ac}}{2a}"#,
            #"x_i^2"#,
            #"\begin{pmatrix}1 & -2\\3 & 4\end{pmatrix}"#,
            #"x_1+x_2+x_3+x_4+x_5+x_6+x_7+x_8+x_9+x_{10}"#
        ]

        for formula in formulas {
            for backend in [FormulaRenderingBackend.legacy, .swiftMath] {
                let result = FormulaReadOnlyRenderProbe.measure(
                    markup: .init(rawValue: formula),
                    options: .init(
                        debugFramesEnabled: false,
                        cursorVisible: false,
                        renderingBackend: backend,
                        fontRole: .standard
                    ),
                    metrics: ObjectPanelFormulaDisplayResolver.makeMetrics(fontSize: 14, minHeight: 24)
                )

                switch result {
                case .success(let measurement):
                    XCTAssertGreaterThan(measurement.width, 0)
                    XCTAssertGreaterThan(measurement.height, 0)
                    XCTAssertTrue(measurement.width.isFinite)
                    XCTAssertTrue(measurement.height.isFinite)
                    XCTAssertTrue(measurement.baseline.isFinite)
                case .failure(let reason, let message):
                    XCTFail("Expected success for \(formula) on \(backend), got \(reason): \(message)")
                }
            }
        }
    }

    func testSmallFontMeasurementsRemainFinite() {
        for size in [12.0, 14.0, 16.0, 18.0] {
            let result = FormulaReadOnlyRenderProbe.measure(
                markup: .init(rawValue: #"\sqrt{\frac{x^2+1}{2}}"#),
                options: .init(
                    debugFramesEnabled: false,
                    cursorVisible: false,
                    renderingBackend: .swiftMath,
                    fontRole: .standard
                ),
                metrics: ObjectPanelFormulaDisplayResolver.makeMetrics(fontSize: size, minHeight: 24)
            )

            guard case .success(let measurement) = result else {
                return XCTFail("Expected measurable SwiftMath output at size \(size)")
            }
            XCTAssertGreaterThan(measurement.width, 0)
            XCTAssertGreaterThan(measurement.height, 0)
        }
    }

    func testConstrainedSingleLineFormulaUsesCompactHeightCap() {
        XCTAssertEqual(
            WorkspaceObjectFormulaDisplayMetrics.maximumFormulaHeight(allowsMultiline: false),
            WorkspaceObjectFormulaDisplayMetrics.compactFormulaMaxHeight
        )
        XCTAssertGreaterThan(
            WorkspaceObjectFormulaDisplayMetrics.maximumFormulaHeight(allowsMultiline: true),
            WorkspaceObjectFormulaDisplayMetrics.maximumFormulaHeight(allowsMultiline: false)
        )
    }

    func testEmptyFormulaProbeReturnsEmptyOutputReason() {
        let result = FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: ""),
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: ObjectPanelFormulaDisplayResolver.makeMetrics(fontSize: 14, minHeight: 24)
        )

        XCTAssertEqual(result, .failure(.emptyOutput, message: "Formula markup is empty."))
    }
}
