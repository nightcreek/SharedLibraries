import XCTest
@testable import EMathicaFormulaDisplayCore

final class PlaceholderQuadComparisonTests: XCTestCase {
    private let fontSizes: [Double] = [16, 24, 36]

    func testPlaceholderAndQuadPairsProduceFiniteSwiftMathMeasurements() {
        let pairs: [(String, String)] = [
            (#"x^{\placeholder{}}"#, #"x^{\quad}"#),
            (#"x_{\placeholder{}}"#, #"x_{\quad}"#),
            (#"\sqrt{\placeholder{}}"#, #"\sqrt{\quad}"#),
            (#"\frac{\placeholder{}}{y}"#, #"\frac{\quad}{y}"#),
            (#"\frac{x}{\placeholder{}}"#, #"\frac{x}{\quad}"#),
            (#"\left(\placeholder{}\right)"#, #"\left(\quad\right)"#),
            (#"\sqrt{x^{\placeholder{}}}"#, #"\sqrt{x^{\quad}}"#)
        ]

        for size in fontSizes {
            for (current, quad) in pairs {
                let currentResult = measure(markup: current, fontSize: size)
                let quadSnapshot = trySnapshot(for: quad, fontSize: size)
                print(measurementLine(label: "current", markup: current, result: currentResult, fontSize: size))
                print(measurementLine(label: "control", markup: quad, snapshot: quadSnapshot, fontSize: size))

                switch currentResult {
                case .success(let measurement):
                    XCTAssertGreaterThan(measurement.width, 0, "Expected positive width for \(current) @ \(size)")
                    XCTAssertGreaterThan(measurement.height, 0, "Expected positive height for \(current) @ \(size)")
                case .failure(let reason, _):
                    XCTAssertTrue(
                        reason == .unsupportedCommand || reason == .parserError,
                        "Unexpected failure kind \(reason.rawValue) for \(current) @ \(size)"
                    )
                }

                XCTAssertGreaterThan(quadSnapshot.size.width, 0, "Expected positive width for \(quad) @ \(size)")
                XCTAssertGreaterThan(quadSnapshot.size.height, 0, "Expected positive height for \(quad) @ \(size)")
            }
        }
    }

    func testQuadControlCasesStayCloseToNormalReferenceHeights() {
        for size in fontSizes {
            assertHeightDelta(
                markup: #"x^{\quad}"#,
                referenceMarkup: #"x^{m}"#,
                fontSize: size,
                maxDelta: 12
            )
            assertHeightDelta(
                markup: #"x_{\quad}"#,
                referenceMarkup: #"x_{m}"#,
                fontSize: size,
                maxDelta: 8
            )
            assertHeightDelta(
                markup: #"\sqrt{\quad}"#,
                referenceMarkup: #"\sqrt{x}"#,
                fontSize: size,
                maxDelta: 8
            )
            assertHeightDelta(
                markup: #"\frac{\quad}{y}"#,
                referenceMarkup: #"\frac{x}{y}"#,
                fontSize: size,
                maxDelta: 18
            )
            assertHeightDelta(
                markup: #"\frac{x}{\quad}"#,
                referenceMarkup: #"\frac{x}{y}"#,
                fontSize: size,
                maxDelta: 10
            )
            assertHeightDelta(
                markup: #"\left(\quad\right)"#,
                referenceMarkup: #"\left(x\right)"#,
                fontSize: size,
                maxDelta: 8
            )
            assertHeightDelta(
                markup: #"\sqrt{x^{\quad}}"#,
                referenceMarkup: #"\sqrt{x^{m}}"#,
                fontSize: size,
                maxDelta: 10
            )
        }
    }

    func testCursorScriptCaseHasStableAnchorAndFiniteBounds() {
        for size in fontSizes {
            let cursorSnapshot = trySnapshot(for: #"x^{\cursor{}}"#, fontSize: size)
            let thinSpaceSnapshot = trySnapshot(for: #"x^{\,}"#, fontSize: size)

            XCTAssertNotNil(cursorSnapshot.cursorAnchor, "Expected cursor anchor @ \(size)")
            XCTAssertLessThanOrEqual(
                abs(cursorSnapshot.size.height - thinSpaceSnapshot.size.height),
                10,
                "Cursor script height drifted too far from thin-space control @ \(size)"
            )
        }
    }

    func testDocumentPlaceholderLoweringSucceedsWithoutUnsupportedCommandAndPreservesIdentity() {
        let placeholderCases: [(title: String, document: FormulaDisplayDocument, expectedContext: FormulaCursorContext)] = [
            ("superscript", documentSuperscriptPlaceholder(), .superscript),
            ("subscript", documentSubscriptPlaceholder(), .subscriptField),
            ("radical", documentRadicalPlaceholder(), .radicalRadicand),
            ("fractionNumerator", documentFractionNumeratorPlaceholder(), .numerator),
            ("fractionDenominator", documentFractionDenominatorPlaceholder(), .denominator),
            ("parentheses", documentParenthesesPlaceholder(), .inline),
            ("nested", documentNestedPlaceholder(), .superscript)
        ]

        for size in fontSizes {
            for testCase in placeholderCases {
                let measurement = FormulaReadOnlyRenderProbe.measure(
                    document: testCase.document,
                    options: .init(renderingBackend: .swiftMath, fontRole: .standard),
                    metrics: .init(baseFontSize: size)
                )
                if case .failure(let reason, let message) = measurement {
                    XCTFail("Expected production placeholder lowering to succeed for \(testCase.title) @ \(size): \(reason.rawValue) \(message)")
                }

                let snapshot = trySnapshot(for: testCase.document, fontSize: size)
                XCTAssertEqual(snapshot.placeholderAnchors.count, 1, "Expected one placeholder anchor for \(testCase.title) @ \(size)")
                guard let anchor = snapshot.placeholderAnchors.first else { continue }
                XCTAssertEqual(anchor.id, "placeholder:\(testCase.title)")
                XCTAssertEqual(anchor.fieldIdentity, testCase.title)
                XCTAssertEqual(anchor.widthPolicy, .quad)
                XCTAssertEqual(anchor.context, testCase.expectedContext)
                XCTAssertGreaterThan(anchor.rect.size.width, 0)
                XCTAssertGreaterThan(anchor.rect.size.height, 0)
                XCTAssertGreaterThan(anchor.ascent, 0)
                XCTAssertGreaterThanOrEqual(anchor.descent, 0)
                XCTAssertEqual(anchor.sourcePath.first, testCase.title)
            }
        }
    }

    func testDocumentCursorSpacingPoliciesMatchMediumAndThickControlsAndStayNarrowerThanPlaceholder() {
        for size in fontSizes {
            let mediumSnapshot = trySnapshot(for: documentCursor(spacing: .medium), fontSize: size)
            let thickSnapshot = trySnapshot(for: documentCursor(spacing: .thick), fontSize: size)
            let mediumControl = trySnapshot(for: #"x\:y"#, fontSize: size)
            let thickControl = trySnapshot(for: #"x\;y"#, fontSize: size)
            let placeholderSnapshot = trySnapshot(for: documentInlinePlaceholder(), fontSize: size)

            guard
                let mediumAnchor = mediumSnapshot.cursorAnchor,
                let thickAnchor = thickSnapshot.cursorAnchor
            else {
                return XCTFail("Expected cursor anchors for \(size)")
            }

            XCTAssertEqual(mediumAnchor.id, "cursor:medium")
            XCTAssertEqual(thickAnchor.id, "cursor:thick")
            XCTAssertEqual(mediumAnchor.fieldIdentity, "medium")
            XCTAssertEqual(thickAnchor.fieldIdentity, "thick")
            XCTAssertEqual(mediumAnchor.sourcePath.first, "medium")
            XCTAssertEqual(thickAnchor.sourcePath.first, "thick")
            XCTAssertLessThan(mediumAnchor.rect.size.width, placeholderSnapshot.placeholderAnchors.first?.rect.size.width ?? .greatestFiniteMagnitude)
            XCTAssertLessThan(thickAnchor.rect.size.width, placeholderSnapshot.placeholderAnchors.first?.rect.size.width ?? .greatestFiniteMagnitude)
            XCTAssertLessThanOrEqual(mediumAnchor.rect.size.width, thickAnchor.rect.size.width)

            let mediumGap = abs((mediumSnapshot.size.width - mediumControl.size.width))
            let thickGap = abs((thickSnapshot.size.width - thickControl.size.width))
            XCTAssertLessThanOrEqual(mediumGap, 2.5, "Expected medium production cursor to track \\: control @ \(size)")
            XCTAssertLessThanOrEqual(thickGap, 4.5, "Expected thick production cursor to stay close to \\; control @ \(size)")
        }
    }

    func testCompleteFormulaRegressionStillProducesFiniteSwiftMathMeasurements() {
        let formulas = [
            "abcde",
            "abcdefghij",
            "x^2",
            "e^{xy}",
            #"\sqrt{x}"#,
            #"\sqrt{x^2+y^2}"#,
            #"\frac{x}{y}"#,
            #"\frac{\sqrt{x^2+1}}{a+b}"#
        ]

        for size in fontSizes {
            for formula in formulas {
                let snapshot = trySnapshot(for: formula, fontSize: size)
                XCTAssertGreaterThan(snapshot.size.width, 0, "Expected finite width for \(formula) @ \(size)")
                XCTAssertGreaterThan(snapshot.size.height, 0, "Expected finite height for \(formula) @ \(size)")
                XCTAssertTrue(snapshot.baseline.isFinite, "Expected finite baseline for \(formula) @ \(size)")
            }
        }
    }

    private func assertHeightDelta(
        markup: String,
        referenceMarkup: String,
        fontSize: Double,
        maxDelta: Double
    ) {
        let markupSnapshot = trySnapshot(for: markup, fontSize: fontSize)
        let referenceSnapshot = trySnapshot(for: referenceMarkup, fontSize: fontSize)
        XCTAssertLessThanOrEqual(
            abs(markupSnapshot.size.height - referenceSnapshot.size.height),
            maxDelta,
            "Expected \(markup) height to stay close to \(referenceMarkup) @ \(fontSize)"
        )
    }

    private func trySnapshot(for markup: String, fontSize: Double) -> FormulaSwiftMathSnapshot {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: markup.contains(#"\cursor"#),
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .init(baseFontSize: fontSize),
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        switch resolved {
        case .swiftMath(let snapshot):
            return snapshot
        case .swiftMathError(let error):
            XCTFail("Expected SwiftMath snapshot for \(markup): \(error.message)")
            fatalError("Missing SwiftMath snapshot")
        case .legacy:
            XCTFail("Expected SwiftMath snapshot for \(markup), received legacy content")
            fatalError("Unexpected legacy content")
        }
    }

    private func trySnapshot(for document: FormulaDisplayDocument, fontSize: Double) -> FormulaSwiftMathSnapshot {
        let resolved = FormulaDisplayContentResolver.resolve(
            document: document,
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: true,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .init(baseFontSize: fontSize),
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        switch resolved {
        case .swiftMath(let snapshot):
            return snapshot
        case .swiftMathError(let error):
            XCTFail("Expected SwiftMath snapshot for document: \(error.message)")
            fatalError("Missing SwiftMath snapshot")
        case .legacy:
            XCTFail("Expected SwiftMath snapshot for document, received legacy content")
            fatalError("Unexpected legacy content")
        }
    }

    private func measure(
        markup: String,
        fontSize: Double
    ) -> FormulaReadOnlyRenderProbeResult {
        FormulaReadOnlyRenderProbe.measure(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: markup.contains(#"\cursor"#),
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .init(baseFontSize: fontSize)
        )
    }

    private func measurementLine(
        label: String,
        markup: String,
        snapshot: FormulaSwiftMathSnapshot,
        fontSize: Double
    ) -> String {
        let ascent = snapshot.baseline
        let descent = max(0, snapshot.size.height - snapshot.baseline)
        return String(
            format: "size=%.0f\t%@\twidth=%.2f\theight=%.2f\tbaseline=%.2f\tascent=%.2f\tdescent=%.2f\tmarkup=%@",
            fontSize,
            label,
            snapshot.size.width,
            snapshot.size.height,
            snapshot.baseline,
            ascent,
            descent,
            markup
        )
    }

    private func measurementLine(
        label: String,
        markup: String,
        result: FormulaReadOnlyRenderProbeResult,
        fontSize: Double
    ) -> String {
        switch result {
        case .success(let measurement):
            let ascent = measurement.baseline
            let descent = max(0, measurement.height - measurement.baseline)
            return String(
                format: "size=%.0f\t%@\tstatus=success\twidth=%.2f\theight=%.2f\tbaseline=%.2f\tascent=%.2f\tdescent=%.2f\tmarkup=%@",
                fontSize,
                label,
                measurement.width,
                measurement.height,
                measurement.baseline,
                ascent,
                descent,
                markup
            )
        case .failure(let reason, let message):
            return "size=\(Int(fontSize))\t\(label)\tstatus=failure\treason=\(reason.rawValue)\tmessage=\(message)\tmarkup=\(markup)"
        }
    }

    private func placeholderToken(_ name: String) -> FormulaDisplayPlaceholderToken {
        .init(
            id: "placeholder:\(name)",
            sourcePath: [name],
            fieldIdentity: name,
            kind: "emptyField",
            widthPolicy: .quad
        )
    }

    private func cursorToken(_ name: String, spacing: FormulaCursorSpacingPolicy) -> FormulaDisplayCursorToken {
        .init(
            id: "cursor:\(name)",
            sourcePath: [name],
            fieldIdentity: name,
            offset: 1,
            spacingPolicy: spacing
        )
    }

    private func documentSuperscriptPlaceholder() -> FormulaDisplayDocument {
        .init(root: .superscript(base: .text("x", role: .symbol), exponent: .placeholder(placeholderToken("superscript"))))
    }

    private func documentSubscriptPlaceholder() -> FormulaDisplayDocument {
        .init(root: .subscript(base: .text("x", role: .symbol), subscriptNode: .placeholder(placeholderToken("subscript"))))
    }

    private func documentRadicalPlaceholder() -> FormulaDisplayDocument {
        .init(root: .sqrt(radicand: .placeholder(placeholderToken("radical"))))
    }

    private func documentFractionNumeratorPlaceholder() -> FormulaDisplayDocument {
        .init(root: .fraction(numerator: .placeholder(placeholderToken("fractionNumerator")), denominator: .text("y", role: .symbol)))
    }

    private func documentFractionDenominatorPlaceholder() -> FormulaDisplayDocument {
        .init(root: .fraction(numerator: .text("x", role: .symbol), denominator: .placeholder(placeholderToken("fractionDenominator"))))
    }

    private func documentParenthesesPlaceholder() -> FormulaDisplayDocument {
        .init(root: .parentheses(content: .placeholder(placeholderToken("parentheses"))))
    }

    private func documentNestedPlaceholder() -> FormulaDisplayDocument {
        .init(
            root: .sqrt(
                radicand: .superscript(
                    base: .text("x", role: .symbol),
                    exponent: .placeholder(placeholderToken("nested"))
                )
            )
        )
    }

    private func documentInlinePlaceholder() -> FormulaDisplayDocument {
        .init(
            root: .sequence([
                .text("x", role: .symbol),
                .placeholder(placeholderToken("inline")),
                .text("y", role: .symbol)
            ])
        )
    }

    private func documentCursor(spacing: FormulaCursorSpacingPolicy) -> FormulaDisplayDocument {
        let name = spacing == .medium ? "medium" : "thick"
        return .init(
            root: .sequence([
                .text("x", role: .symbol),
                .cursor(cursorToken(name, spacing: spacing)),
                .text("y", role: .symbol)
            ])
        )
    }
}
