import SwiftUI
import XCTest
@testable import EMathicaFormulaDisplayCore
@testable import EMathicaFormulaDisplaySwiftUI

final class FormulaReadOnlyRenderingTests: XCTestCase {
    func testContentInspectorTreatsCursorOnlyDocumentAndMarkupAsEmpty() {
        let document = FormulaDisplayDocument(root: .sequence([.cursor(.anonymous)]))
        let markup = FormulaDisplayMarkup(rawValue: #"\cursor{}"#)

        XCTAssertTrue(FormulaDisplayContentInspector.isEffectivelyEmpty(document))
        XCTAssertTrue(FormulaDisplayContentInspector.isEffectivelyEmpty(markup))
    }

    func testContentInspectorKeepsStructuralEmptyFormulaNonEmpty() {
        let document = FormulaDisplayDocument(
            root: .sqrt(
                radicand: .sequence([
                    .placeholder(.init(id: "placeholder:sqrt", sourcePath: ["sqrt"], fieldIdentity: "radicand", kind: "radicand"))
                ])
            )
        )

        XCTAssertFalse(FormulaDisplayContentInspector.isEffectivelyEmpty(document))
    }

    func testCoreResolverUsesSwiftMathBackendByDefault() {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: "x+1"),
            options: .default,
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved else {
            return XCTFail("Expected SwiftMath snapshot by default")
        }

        XCTAssertFalse(snapshot.pngData.isEmpty)
        XCTAssertGreaterThan(snapshot.size.width, 0)
        XCTAssertGreaterThan(snapshot.size.height, 0)
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

    func testSwiftMathLoweringPreservesNestedStructuresAndUsesMathFunctionCommands() {
        let cases: [(String, FormulaDisplayDocument, String, String)] = [
            (
                "absoluteValueNestedSqrt",
                .init(
                    root: .absoluteValue(
                        content: .sqrt(
                            radicand: .sequence([
                                .placeholder(.init(id: "placeholder:absolute", sourcePath: ["absolute"], fieldIdentity: "radicand", kind: "radicand"))
                            ])
                        )
                    )
                ),
                #"|\sqrt{\quad}|"#,
                #"|\sqrt{\emplaceholder{}}|"#
            ),
            (
                "fractionNestedSqrt",
                .init(
                    root: .fraction(
                        numerator: .sqrt(
                            radicand: .sequence([
                                .placeholder(.init(id: "placeholder:fraction", sourcePath: ["fraction"], fieldIdentity: "radicand", kind: "radicand"))
                            ])
                        ),
                        denominator: .sequence([.text("y", role: .symbol)])
                    )
                ),
                #"\frac{\sqrt{\quad}}{y}"#,
                #"\frac{\sqrt{\emplaceholder{}}}{y}"#
            ),
            (
                "superscriptNestedSqrt",
                .init(
                    root: .superscript(
                        base: .sequence([.text("x", role: .symbol)]),
                        exponent: .sqrt(
                            radicand: .sequence([
                                .placeholder(.init(id: "placeholder:superscript", sourcePath: ["superscript"], fieldIdentity: "radicand", kind: "radicand"))
                            ])
                        )
                    )
                ),
                #"x^{\sqrt{\quad}}"#,
                #"x^{\sqrt{\emplaceholder{}}}"#
            ),
            (
                "sinNestedSqrt",
                .init(
                    root: .function(
                        name: "sin",
                        arguments: [
                            .sqrt(
                                radicand: .sequence([
                                    .placeholder(.init(id: "placeholder:sin", sourcePath: ["sin"], fieldIdentity: "radicand", kind: "radicand"))
                                ])
                            )
                        ]
                    )
                ),
                #"\sin(\sqrt{\quad})"#,
                #"\sin(\sqrt{\emplaceholder{}})"#
            ),
            (
                "matrixNestedSqrt",
                .init(
                    root: .matrix(
                        environment: .bmatrix,
                        rows: [
                            .init(
                                cells: [
                                    .sqrt(
                                        radicand: .sequence([
                                            .placeholder(.init(id: "placeholder:matrix", sourcePath: ["matrix"], fieldIdentity: "radicand", kind: "radicand"))
                                        ])
                                    ),
                                    .text("y", role: .symbol)
                                ]
                            )
                        ]
                    )
                ),
                #"\begin{bmatrix}\sqrt{\quad}&y\end{bmatrix}"#,
                #"\begin{bmatrix}\sqrt{\emplaceholder{}}&y\end{bmatrix}"#
            ),
            (
                "piecewiseNestedAbsolute",
                .init(
                    root: .piecewise(
                        rows: [
                            .init(
                                expression: .text("x", role: .symbol),
                                condition: .absoluteValue(
                                    content: .sequence([
                                        .placeholder(.init(id: "placeholder:piecewise", sourcePath: ["piecewise"], fieldIdentity: "content", kind: "content"))
                                    ])
                                )
                            ),
                            .init(
                                expression: .text("y", role: .symbol),
                                condition: .text("z", role: .symbol)
                            )
                        ]
                    )
                ),
                #"\begin{cases}x,&|\quad|\\\\y,&z\end{cases}"#,
                #"\begin{cases}x,&|\emplaceholder{}|\\\\y,&z\end{cases}"#
            )
        ]

        for (title, document, expectedLatex, expectedAnchorLatex) in cases {
            let lowered = FormulaDisplaySwiftMathLowerer.lower(document)
            XCTAssertEqual(lowered.latex, expectedLatex, "Unexpected lowering for \(title)")
            XCTAssertEqual(lowered.anchorLatex, expectedAnchorLatex, "Unexpected anchor lowering for \(title)")
        }
    }

    func testSwiftMathResolverPreservesPlaceholderIdentityWhileVisibleLatexUsesQuadLeaves() {
        let document = FormulaDisplayDocument(
            root: .absoluteValue(
                content: .sqrt(
                    radicand: .sequence([
                        .placeholder(.init(id: "placeholder:absolute", sourcePath: ["absolute"], fieldIdentity: "radicand", kind: "radicand"))
                    ])
                )
            )
        )

        let lowered = FormulaDisplaySwiftMathLowerer.lower(document)
        XCTAssertEqual(lowered.latex, #"|\sqrt{\quad}|"#)
        XCTAssertEqual(lowered.anchorLatex, #"|\sqrt{\emplaceholder{}}|"#)

        let resolved = FormulaDisplayContentResolver.resolve(
            document: document,
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved else {
            return XCTFail("Expected SwiftMath snapshot")
        }

        XCTAssertEqual(snapshot.placeholderAnchors.count, 1)
        XCTAssertEqual(snapshot.placeholderAnchors.first?.id, "placeholder:absolute")
        XCTAssertEqual(snapshot.placeholderAnchors.first?.fieldIdentity, "radicand")
        XCTAssertGreaterThan(snapshot.size.width, 0)
        XCTAssertGreaterThan(snapshot.size.height, 0)
    }
}

@MainActor
final class FormulaReadOnlyRenderingViewTests: XCTestCase {
    func testCursorOnlyFormulaDisplayViewCanInitializeWithoutVisibleErrorState() {
        let view = FormulaDisplayView(
            markup: .init(rawValue: #"\cursor{}"#),
            style: .default,
            options: .init(renderingBackend: .swiftMath, fontRole: .standard),
            metrics: .init(baseFontSize: 22)
        )

        XCTAssertNotNil(view)
    }

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
