import XCTest
@testable import EMathicaFormulaDisplayCore

final class SwiftMathCursorGeometryTests: XCTestCase {
    func testCursorAnchorCoordinatesAreNormalizedToTopLeadingSpace() {
        let inlineAnchor = assertCursorAnchor(for: #"x+\cursor{}+y"#)
        let superscriptAnchor = assertCursorAnchor(for: #"x^{\cursor{}}"#)
        let subscriptAnchor = assertCursorAnchor(for: #"x_{\cursor{}}"#)
        let numeratorAnchor = assertCursorAnchor(for: #"\frac{\cursor{}}{y}"#)
        let denominatorAnchor = assertCursorAnchor(for: #"\frac{x}{\cursor{}}"#)
        let radicalAnchor = assertCursorAnchor(for: #"\sqrt{\cursor{}}"#)

        XCTAssertLessThan(superscriptAnchor.rect.minY, inlineAnchor.rect.minY)
        XCTAssertGreaterThan(subscriptAnchor.rect.minY, inlineAnchor.rect.minY)
        XCTAssertLessThan(numeratorAnchor.rect.minY, denominatorAnchor.rect.minY)
        XCTAssertLessThanOrEqual(radicalAnchor.rect.minY, denominatorAnchor.rect.maxY)

        for anchor in [inlineAnchor, superscriptAnchor, subscriptAnchor, numeratorAnchor, denominatorAnchor, radicalAnchor] {
            XCTAssertGreaterThanOrEqual(anchor.baseline, anchor.rect.minY)
            XCTAssertLessThanOrEqual(anchor.baseline, anchor.rect.maxY)
        }
    }

    func testPlaceholderAnchorsAreNormalizedToTopLeadingSpace() {
        let inline = assertPlaceholderAnchor(
            in: documentWithPlaceholder(
                sourcePath: ["inline"],
                fieldIdentity: "inline",
                node: .sequence([
                    .text("x", role: .symbol),
                    .placeholder(.init(id: "placeholder:inline", sourcePath: ["inline"], fieldIdentity: "inline"))
                ])
            )
        )
        let superscript = assertPlaceholderAnchor(
            in: documentWithPlaceholder(
                sourcePath: ["superscript"],
                fieldIdentity: "exponent",
                node: .superscript(
                    base: .sequence([.text("x", role: .symbol)]),
                    exponent: .sequence([
                        .text("2", role: .number),
                        .placeholder(.init(id: "placeholder:superscript", sourcePath: ["superscript"], fieldIdentity: "exponent"))
                    ])
                )
            )
        )
        let subscriptAnchor = assertPlaceholderAnchor(
            in: documentWithPlaceholder(
                sourcePath: ["subscript"],
                fieldIdentity: "subscript",
                node: .subscript(
                    base: .sequence([.text("x", role: .symbol)]),
                    subscriptNode: .sequence([
                        .text("i", role: .symbol),
                        .placeholder(.init(id: "placeholder:subscript", sourcePath: ["subscript"], fieldIdentity: "subscript"))
                    ])
                )
            )
        )
        let numerator = assertPlaceholderAnchor(
            in: documentWithPlaceholder(
                sourcePath: ["fraction", "numerator"],
                fieldIdentity: "numerator",
                node: .fraction(
                    numerator: .sequence([
                        .text("a", role: .symbol),
                        .placeholder(.init(id: "placeholder:numerator", sourcePath: ["fraction", "numerator"], fieldIdentity: "numerator"))
                    ]),
                    denominator: .sequence([.text("y", role: .symbol)])
                )
            )
        )
        let denominator = assertPlaceholderAnchor(
            in: documentWithPlaceholder(
                sourcePath: ["fraction", "denominator"],
                fieldIdentity: "denominator",
                node: .fraction(
                    numerator: .sequence([.text("x", role: .symbol)]),
                    denominator: .sequence([
                        .text("b", role: .symbol),
                        .placeholder(.init(id: "placeholder:denominator", sourcePath: ["fraction", "denominator"], fieldIdentity: "denominator"))
                    ])
                )
            )
        )

        XCTAssertGreaterThan(subscriptAnchor.rect.minY, inline.rect.minY)
        XCTAssertLessThan(numerator.rect.minY, denominator.rect.minY)
        for anchor in [inline, superscript, subscriptAnchor, numerator, denominator] {
            XCTAssertGreaterThanOrEqual(anchor.baseline, anchor.rect.minY)
            XCTAssertLessThanOrEqual(anchor.baseline, anchor.rect.maxY)
        }
    }

    func testInsertionAnchorsAreNormalizedToTopLeadingSpace() {
        let inline = assertInsertionAnchor(
            in: documentWithInsertion(
                node: .sequence([
                    .text("x", role: .symbol),
                    .insertionMarker(
                        .init(
                            id: .init(sourcePath: ["inline"], offset: 1, affinity: .interior),
                            sourcePath: ["inline"],
                            fieldIdentity: "inline",
                            offset: 1,
                            affinity: .interior
                        )
                    ),
                    .text("y", role: .symbol)
                ])
            )
        )
        let superscript = assertInsertionAnchor(
            in: documentWithInsertion(
                node: .superscript(
                    base: .sequence([.text("x", role: .symbol)]),
                    exponent: .sequence([
                        .text("2", role: .number),
                        .insertionMarker(
                            .init(
                                id: .init(sourcePath: ["superscript"], offset: 1, affinity: .interior),
                                sourcePath: ["superscript"],
                                fieldIdentity: "exponent",
                                offset: 1,
                                affinity: .interior
                            )
                        ),
                        .text("3", role: .number)
                    ])
                )
            )
        )
        let subscriptAnchor = assertInsertionAnchor(
            in: documentWithInsertion(
                node: .subscript(
                    base: .sequence([.text("x", role: .symbol)]),
                    subscriptNode: .sequence([
                        .text("i", role: .symbol),
                        .insertionMarker(
                            .init(
                                id: .init(sourcePath: ["subscript"], offset: 1, affinity: .interior),
                                sourcePath: ["subscript"],
                                fieldIdentity: "subscript",
                                offset: 1,
                                affinity: .interior
                            )
                        ),
                        .text("j", role: .symbol)
                    ])
                )
            )
        )
        let numerator = assertInsertionAnchor(
            in: documentWithInsertion(
                node: .fraction(
                    numerator: .sequence([
                        .text("a", role: .symbol),
                        .insertionMarker(
                            .init(
                                id: .init(sourcePath: ["fraction", "numerator"], offset: 1, affinity: .interior),
                                sourcePath: ["fraction", "numerator"],
                                fieldIdentity: "numerator",
                                offset: 1,
                                affinity: .interior
                            )
                        ),
                        .text("b", role: .symbol)
                    ]),
                    denominator: .sequence([.text("y", role: .symbol)])
                )
            )
        )
        let denominator = assertInsertionAnchor(
            in: documentWithInsertion(
                node: .fraction(
                    numerator: .sequence([.text("x", role: .symbol)]),
                    denominator: .sequence([
                        .text("c", role: .symbol),
                        .insertionMarker(
                            .init(
                                id: .init(sourcePath: ["fraction", "denominator"], offset: 1, affinity: .interior),
                                sourcePath: ["fraction", "denominator"],
                                fieldIdentity: "denominator",
                                offset: 1,
                                affinity: .interior
                            )
                        ),
                        .text("d", role: .symbol)
                    ])
                )
            )
        )
        let activeSuperscriptCursor = assertCursorAnchor(for: #"x^{2\cursor{}3}"#)

        XCTAssertEqual(superscript.rect.minY, activeSuperscriptCursor.rect.minY, accuracy: 0.001)
        XCTAssertGreaterThan(subscriptAnchor.rect.minY, inline.rect.minY)
        XCTAssertLessThan(numerator.rect.minY, denominator.rect.minY)
        for anchor in [inline, superscript, subscriptAnchor, numerator, denominator] {
            XCTAssertGreaterThanOrEqual(anchor.baseline, anchor.rect.minY)
            XCTAssertLessThanOrEqual(anchor.baseline, anchor.rect.maxY)
        }
    }

    func testCursorAnchorExistsForInlineFormula() {
        let anchor = assertCursorAnchor(for: #"x+\cursor{}+y"#)
        XCTAssertEqual(anchor.context, .inline)
        XCTAssertNil(anchor.offset)
    }

    func testCursorAnchorExistsInsideFraction() {
        let anchor = assertCursorAnchor(for: #"\frac{x+\cursor{}}{y}"#)
        XCTAssertEqual(anchor.context, .numerator)
    }

    func testCursorAnchorExistsInsideRadical() {
        let anchor = assertCursorAnchor(for: #"\sqrt{x+\cursor{}}"#)
        XCTAssertEqual(anchor.context, .radicalRadicand)
    }

    func testCursorAnchorExistsInsideSuperscript() {
        let anchor = assertCursorAnchor(for: #"x^{\cursor{}}"#)
        XCTAssertEqual(anchor.context, .superscript)
    }

    func testCursorAnchorExistsInsideSubscript() {
        let anchor = assertCursorAnchor(for: #"x_{\cursor{}}"#)
        XCTAssertEqual(anchor.context, .subscriptField)
    }

    func testCursorAnchorExistsInsideDenominator() {
        let anchor = assertCursorAnchor(for: #"\frac{x}{\cursor{}}"#)
        XCTAssertEqual(anchor.context, .denominator)
    }

    func testCursorPlaceholderDoesNotBlowUpRadicalOrFractionHeight() {
        let baseSqrt = measureSnapshot(for: #"\sqrt{x+y}"#)
        let cursorSqrt = measureSnapshot(for: #"\sqrt{x+\cursor{}+y}"#)
        XCTAssertLessThanOrEqual(cursorSqrt.size.height - baseSqrt.size.height, 6)

        let baseFraction = measureSnapshot(for: #"\frac{\sqrt{x+y}}{y}"#)
        let cursorFraction = measureSnapshot(for: #"\frac{\sqrt{x+\cursor{}+y}}{y}"#)
        XCTAssertLessThanOrEqual(cursorFraction.size.height - baseFraction.size.height, 6)
    }

    @discardableResult
    private func assertCursorAnchor(for markup: String) -> FormulaCursorAnchor {
        let snapshot = measureSnapshot(for: markup)

        guard let anchor = snapshot.cursorAnchor else {
            XCTFail("Expected cursor anchor for \(markup)")
            fatalError("Missing cursor anchor")
        }

        XCTAssertGreaterThan(anchor.rect.size.width, 0, "Expected positive cursor width for \(markup)")
        XCTAssertGreaterThan(anchor.rect.size.height, 0, "Expected positive cursor height for \(markup)")
        XCTAssertGreaterThan(anchor.ascent, 0, "Expected positive cursor ascent for \(markup)")
        XCTAssertGreaterThanOrEqual(anchor.descent, 0, "Expected non-negative cursor descent for \(markup)")
        XCTAssertGreaterThanOrEqual(anchor.baseline, 0, "Expected non-negative baseline for \(markup)")
        return anchor
    }

    private func measureSnapshot(for markup: String) -> FormulaSwiftMathSnapshot {
        let resolved = FormulaDisplayContentResolver.resolve(
            markup: .init(rawValue: markup),
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: true,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved else {
            XCTFail("Expected SwiftMath snapshot for \(markup)")
            fatalError("Missing SwiftMath snapshot")
        }
        return snapshot
    }

    private func measureSnapshot(for document: FormulaDisplayDocument) -> FormulaSwiftMathSnapshot {
        let resolved = FormulaDisplayContentResolver.resolve(
            document: document,
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: true,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved else {
            XCTFail("Expected SwiftMath snapshot for document")
            fatalError("Missing SwiftMath snapshot")
        }
        return snapshot
    }

    private func assertPlaceholderAnchor(in document: FormulaDisplayDocument) -> FormulaPlaceholderAnchor {
        let snapshot = measureSnapshot(for: document)
        guard let anchor = snapshot.placeholderAnchors.first else {
            XCTFail("Expected placeholder anchor")
            fatalError("Missing placeholder anchor")
        }
        return anchor
    }

    private func assertInsertionAnchor(in document: FormulaDisplayDocument) -> FormulaInsertionAnchor {
        let snapshot = measureSnapshot(for: document)
        guard let anchor = snapshot.insertionAnchors.first else {
            XCTFail("Expected insertion anchor")
            fatalError("Missing insertion anchor")
        }
        return anchor
    }

    private func documentWithPlaceholder(sourcePath: [String], fieldIdentity: String, node: FormulaDisplayNode) -> FormulaDisplayDocument {
        _ = sourcePath
        _ = fieldIdentity
        return .init(root: node)
    }

    private func documentWithInsertion(node: FormulaDisplayNode) -> FormulaDisplayDocument {
        .init(root: node)
    }

    func testDocumentCursorAnchorCarriesStructuredOffsetAndFieldIdentity() {
        let document = FormulaDisplayDocument(
            root: .sequence([
                .text("x", role: .symbol),
                .cursor(
                    .init(
                        id: "cursor:field.argument@1",
                        sourcePath: ["field.argument"],
                        fieldIdentity: "argument",
                        offset: 1,
                        spacingPolicy: .medium
                    )
                )
            ])
        )

        let resolved = FormulaDisplayContentResolver.resolve(
            document: document,
            options: .init(
                debugFramesEnabled: false,
                cursorVisible: true,
                renderingBackend: .swiftMath,
                fontRole: .standard
            ),
            metrics: .default,
            foregroundColor: .init(red: 0, green: 0, blue: 0, alpha: 1)
        )

        guard case .swiftMath(let snapshot) = resolved,
              let anchor = snapshot.cursorAnchor else {
            return XCTFail("Expected cursor anchor from document path")
        }

        XCTAssertEqual(anchor.id, "cursor:field.argument@1")
        XCTAssertEqual(anchor.sourcePath, ["field.argument"])
        XCTAssertEqual(anchor.fieldIdentity, "argument")
        XCTAssertEqual(anchor.offset, 1)
    }
}
