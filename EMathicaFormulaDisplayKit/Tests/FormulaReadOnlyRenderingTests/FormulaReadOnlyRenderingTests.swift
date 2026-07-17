import SwiftUI
import XCTest
@testable import EMathicaFormulaDisplayCore
@testable import EMathicaFormulaDisplaySwiftUI

final class FormulaReadOnlyRenderingTests: XCTestCase {
    func testCoreResolverUsesLegacyBackendByDefault() {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: "x+1"),
            options: .default,
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .legacy(let plan) = resolved else {
            return XCTFail("Expected legacy render plan by default")
        }

        XCTAssertGreaterThan(plan.size.width, 0)
        XCTAssertFalse(plan.elements.isEmpty)
    }

    func testCoreResolverProducesSwiftMathSnapshotWhenExplicitlyEnabled() {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: #"\begin{pmatrix}1 & -2\\3 & 4\end{pmatrix}"#),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: false,
                renderingBackend: .swiftMath,
                fontRole: .decorative
            ),
            metrics: .init(baseFontSize: 24),
            foregroundColor: .init(red: 0.1, green: 0.2, blue: 0.3, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved else {
            return XCTFail("Expected SwiftMath snapshot")
        }

        XCTAssertFalse(snapshot.pngData.isEmpty)
        XCTAssertGreaterThan(snapshot.size.width, 0)
        XCTAssertGreaterThan(snapshot.size.height, 0)
        XCTAssertGreaterThanOrEqual(snapshot.baseline, 0)
    }

    func testCoreResolverReportsKnownUnsupportedMathscr() {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: #"\mathscr{L}"#),
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMathError(let error) = resolved else {
            return XCTFail("Expected SwiftMath diagnostic error")
        }

        XCTAssertTrue(error.message.contains(#"\mathscr"#))
    }
}

@MainActor
final class FormulaReadOnlyRenderingViewTests: XCTestCase {
    func testFormulaDisplayViewCanUseSwiftMathBackend() {
        let view = FormulaDisplayView(
            markup: .init(rawValue: #"\frac{1}{1+\sqrt{2}}"#),
            style: .default,
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: .init(baseFontSize: 22)
        )

        XCTAssertNotNil(view)
    }

    func testDedicatedSwiftMathFormulaViewCanInitialize() {
        let view = SwiftMathFormulaView(
            markup: .init(rawValue: #"\int_0^\infty e^{-x^2}\,dx"#),
            fontRole: .handwrittenResult,
            fontSize: 24,
            foregroundColor: .primary
        )

        XCTAssertNotNil(view)
    }
}
