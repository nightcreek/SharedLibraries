import XCTest
import EMathicaFormulaDisplayCore
@testable import EMathicaMathInputCore

final class FormulaDisplayBridgeTests: XCTestCase {
    func testBridgeBuildsDisplayDocumentWithoutExposingMathInputAST() {
        let formula = MathFormula.sequence([
            .symbol("x"),
            .operatorSymbol("+"),
            .template(
                MathTemplateFormula(
                    kind: .fraction,
                    fields: [
                        .sequence([.number("1")]),
                        .sequence([])
                    ]
                )
            )
        ])

        let document = FormulaDisplayBridge.document(
            source: formula,
            cursor: .init(editorCursor: .init(path: [.sequenceIndex(2), .templateField(.denominator)], offset: 0))
        )

        guard case .sequence(let rootNodes) = document.root else {
            return XCTFail("Expected root sequence")
        }
        XCTAssertEqual(rootNodes.count, 3)
        XCTAssertEqual(rootNodes[0], .text("x", role: .symbol))
        XCTAssertEqual(rootNodes[1], .operatorSymbol("+"))
        guard case .fraction(let numerator, let denominator) = rootNodes[2] else {
            return XCTFail("Expected fraction node")
        }
        XCTAssertEqual(numerator, .sequence([.text("1", role: .number)]))
        guard case .sequence(let denominatorNodes) = denominator else {
            return XCTFail("Expected denominator sequence")
        }
        XCTAssertEqual(denominatorNodes.count, 2)
        guard case .cursor(let cursorToken) = denominatorNodes[0] else {
            return XCTFail("Expected cursor token in denominator")
        }
        XCTAssertEqual(cursorToken.id, "cursor:sequence[2]/field.denominator@0")
        XCTAssertEqual(cursorToken.sourcePath, ["sequence[2]", "field.denominator"])
        XCTAssertEqual(cursorToken.fieldIdentity, "denominator")
        XCTAssertEqual(cursorToken.offset, 0)
        XCTAssertEqual(cursorToken.spacingPolicy, .medium)

        guard case .placeholder(let placeholderToken) = denominatorNodes[1] else {
            return XCTFail("Expected placeholder token in denominator")
        }
        XCTAssertEqual(placeholderToken.id, "placeholder:sequence[2]/field.denominator")
        XCTAssertEqual(placeholderToken.sourcePath, ["sequence[2]", "field.denominator"])
        XCTAssertEqual(placeholderToken.fieldIdentity, "denominator")
        XCTAssertEqual(placeholderToken.kind, "denominator")
        XCTAssertEqual(placeholderToken.widthPolicy, .quad)
    }

    func testBridgeMarkupRoundTripsThroughDocumentSerializer() {
        let formula = MathFormula.sequence([
            .template(
                MathTemplateFormula(
                    kind: .sqrt,
                    fields: [
                        .sequence([.symbol("x"), .operatorSymbol("+"), .number("1")])
                    ]
                )
            )
        ])

        let markup = FormulaDisplayBridge.markup(
            source: formula,
            cursor: .init(editorCursor: .init(path: [], offset: 1))
        )
        let document = FormulaDisplayBridge.document(
            source: formula,
            cursor: .init(editorCursor: .init(path: [], offset: 1))
        )

        XCTAssertEqual(markup.rawValue, #"\sqrt{x+1}\cursor{}"#)
        XCTAssertEqual(markup.rawValue, FormulaDisplayDocumentSerializer.serialize(document))
    }

    func testBridgeDisplaysMultiplicationAsCdotWithoutChangingSourceSerialization() {
        let formula = MathFormula.sequence([
            .symbol("a"),
            .operatorSymbol("*"),
            .symbol("b")
        ])
        let document = FormulaDisplayBridge.document(source: formula)
        let state = EditorState(root: .sequence([.symbol("a"), .operatorSymbol("*"), .symbol("b")]))

        XCTAssertEqual(FormulaDisplayDocumentSerializer.serialize(document), #"a\cdotb"#)
        XCTAssertEqual(SourceSerializer().serialize(state), "a*b")
    }

    func testBridgePreservesNestedEmptyTemplateStructureInDocument() {
        let formula = MathFormula.sequence([
            .template(
                MathTemplateFormula(
                    kind: .absoluteValue,
                    fields: [
                        .template(
                            MathTemplateFormula(
                                kind: .sqrt,
                                fields: [
                                    .sequence([])
                                ]
                            )
                        )
                    ]
                )
            ),
            .template(
                MathTemplateFormula(
                    kind: .fraction,
                    fields: [
                        .template(
                            MathTemplateFormula(
                                kind: .sqrt,
                                fields: [
                                    .sequence([])
                                ]
                            )
                        ),
                        .symbol("y")
                    ]
                )
            )
        ])

        let document = FormulaDisplayBridge.document(source: formula)

        guard case .sequence(let rootNodes) = document.root else {
            return XCTFail("Expected root sequence")
        }

        guard case .absoluteValue(let absContent) = rootNodes[0] else {
            return XCTFail("Expected absoluteValue")
        }
        guard case .sqrt(let radicand) = absContent else {
            return XCTFail("Expected nested sqrt inside absoluteValue")
        }
        guard case .sequence(let radicandNodes) = radicand else {
            return XCTFail("Expected radicand sequence")
        }
        XCTAssertEqual(radicandNodes.count, 1)
        guard case .placeholder(let absPlaceholder) = radicandNodes[0] else {
            return XCTFail("Expected placeholder in nested radicand")
        }
        XCTAssertEqual(absPlaceholder.fieldIdentity, "radicand")

        guard case .fraction(let numerator, let denominator) = rootNodes[1] else {
            return XCTFail("Expected fraction")
        }
        guard case .sqrt(let numeratorSqrt) = numerator else {
            return XCTFail("Expected nested sqrt in numerator")
        }
        guard case .sequence(let numeratorNodes) = numeratorSqrt else {
            return XCTFail("Expected numerator radicand sequence")
        }
        XCTAssertEqual(numeratorNodes.count, 1)
        guard case .placeholder(let numeratorPlaceholder) = numeratorNodes[0] else {
            return XCTFail("Expected placeholder in nested numerator radicand")
        }
        XCTAssertEqual(numeratorPlaceholder.fieldIdentity, "radicand")
        XCTAssertEqual(denominator, .text("y", role: .symbol))
    }

    func testBridgePreservesWrappedNestedStructuresFromProjectedFields() {
        let formula = MathFormula.sequence([
            .template(
                MathTemplateFormula(
                    kind: .absoluteValue,
                    fields: [
                        .template(
                            MathTemplateFormula(
                                kind: .sqrt,
                                fields: [.sequence([])]
                            )
                        )
                    ]
                )
            ),
            .function(
                .init(
                    name: "sin",
                    arguments: [
                        .template(
                            MathTemplateFormula(
                                kind: .sqrt,
                                fields: [.sequence([])]
                            )
                        )
                    ]
                )
            ),
            .template(
                MathTemplateFormula(
                    kind: .parametric2D,
                    fields: [
                        .template(
                            MathTemplateFormula(
                                kind: .sqrt,
                                fields: [.sequence([])]
                            )
                        ),
                        .sequence([.symbol("y")]),
                        .sequence([.symbol("t")])
                    ]
                )
            )
        ])

        let document = FormulaDisplayBridge.document(source: formula)

        guard case .sequence(let rootNodes) = document.root else {
            return XCTFail("Expected root sequence")
        }

        guard case .absoluteValue(let absContent) = rootNodes[0] else {
            return XCTFail("Expected absoluteValue")
        }
        guard case .sqrt(let absRadicand) = absContent else {
            return XCTFail("Expected sqrt inside absoluteValue")
        }
        guard case .sequence(let absNodes) = absRadicand, absNodes.count == 1 else {
            return XCTFail("Expected placeholder sequence inside absoluteValue sqrt")
        }

        guard case .function(let name, let arguments) = rootNodes[1] else {
            return XCTFail("Expected function node")
        }
        XCTAssertEqual(name, "sin")
        XCTAssertEqual(arguments.count, 1)
        guard case .sqrt(let functionRadicand) = arguments[0] else {
            return XCTFail("Expected sqrt function argument")
        }
        guard case .sequence(let functionNodes) = functionRadicand, functionNodes.count == 1 else {
            return XCTFail("Expected placeholder sequence inside function sqrt")
        }

        guard case .parametric2D(let x, let y, let range) = rootNodes[2] else {
            return XCTFail("Expected parametric2D")
        }
        guard case .sqrt(let parametricX) = x else {
            return XCTFail("Expected sqrt in parametric x field")
        }
        guard case .sequence(let parametricXNodes) = parametricX, parametricXNodes.count == 1 else {
            return XCTFail("Expected placeholder sequence inside parametric sqrt")
        }
        XCTAssertEqual(y, .sequence([.text("y", role: .symbol)]))
        XCTAssertEqual(range, .sequence([.text("t", role: .symbol)]))
    }

    func testBridgeCanEmitStableInsertionMarkersForSequences() {
        let formula = MathFormula.sequence([
            .symbol("x"),
            .operatorSymbol("+"),
            .symbol("y")
        ])

        let document = FormulaDisplayBridge.document(
            source: formula,
            includesInsertionMarkers: true
        )

        guard case .sequence(let rootNodes) = document.root else {
            return XCTFail("Expected root sequence")
        }

        XCTAssertEqual(rootNodes.count, 7)

        let insertionTokens = rootNodes.compactMap { node -> FormulaDisplayInsertionToken? in
            guard case .insertionMarker(let token) = node else { return nil }
            return token
        }

        XCTAssertEqual(insertionTokens.count, 4)
        XCTAssertEqual(
            insertionTokens.map(\.id.stableStringValue),
            [
                "insertion:root@0#leading",
                "insertion:root@1#interior",
                "insertion:root@2#interior",
                "insertion:root@3#trailing"
            ]
        )
        XCTAssertTrue(insertionTokens.allSatisfy { $0.spacingPolicy == .zero })
    }

    func testProjectionSnapshotMapsInsertionIDsBackToEditorCursors() {
        let formula = MathFormula.sequence([
            .template(
                MathTemplateFormula(
                    kind: .sqrt,
                    fields: [
                        .sequence([])
                    ]
                )
            )
        ])

        let snapshot = FormulaDisplayProjection.displayProjectionSnapshot(
            source: formula,
            includesInsertionMarkers: true
        )

        let leadingID = FormulaInsertionID(
            sourcePath: ["sequence[0]", "field.radicand"],
            offset: 0,
            affinity: .leading
        )
        let trailingID = FormulaInsertionID(
            sourcePath: ["sequence[0]", "field.radicand"],
            offset: 1,
            affinity: .trailing
        )

        XCTAssertEqual(
            snapshot.cursor(for: leadingID),
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.radicand)],
                offset: 0
            )
        )
        XCTAssertEqual(
            snapshot.cursor(for: trailingID),
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.radicand)],
                offset: 1
            )
        )
        XCTAssertEqual(snapshot.insertionCursors[leadingID], snapshot.cursor(for: leadingID))
        XCTAssertEqual(snapshot.document, FormulaDisplayBridge.document(source: formula, includesInsertionMarkers: true))
    }

    func testProjectionSnapshotMapsNestedSequenceFieldInsertionToValidEditorCursor() {
        let formula = MathFormula.sequence([
            .template(
                MathTemplateFormula(
                    kind: .parametric2D,
                    fields: [
                        .sequence([.symbol("x")]),
                        .sequence([.symbol("y")]),
                        .sequence([.symbol("y")])
                    ]
                )
            )
        ])
        let editorState = EditorState(
            root: .sequence([
                .template(
                    TemplateNode(
                        kind: .parametricEquation2D,
                        fields: [
                            TemplateField(id: .parametricExpression(0), node: .sequence([.symbol("x")])),
                            TemplateField(id: .parametricExpression(1), node: .sequence([.symbol("y")])),
                            TemplateField(id: .parametricRange, node: .sequence([.symbol("y")]))
                        ]
                    )
                )
            ])
        )

        let snapshot = FormulaDisplayBridge.projectionSnapshot(
            source: formula,
            includesInsertionMarkers: true
        )

        let targetID = FormulaInsertionID(
            sourcePath: ["sequence[0]", "field.parametricRange"],
            offset: 1,
            affinity: .trailing
        )

        guard let cursor = snapshot.cursor(for: targetID) else {
            return XCTFail("Expected target insertion cursor")
        }
        XCTAssertEqual(
            cursor,
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.parametricRange)],
                offset: 1
            )
        )
        XCTAssertNotNil(MathEditorTree.sequence(at: cursor.path, in: editorState.root))
        XCTAssertEqual(MathEditorTree.sequence(at: cursor.path, in: editorState.root)?.count, 1)
    }

    func testProjectionSnapshotKeepsRepresentativeNestedInsertionCursorsEditorValid() {
        let cases: [(source: MathFormula, editorRoot: MathNode)] = [
            (
                source: .sequence([
                    .template(
                        MathTemplateFormula(
                            kind: .superscript,
                            fields: [
                                .sequence([.symbol("x")]),
                                .sequence([.symbol("2")])
                            ]
                        )
                    )
                ]),
                editorRoot: .sequence([
                    .template(
                        TemplateNode(
                            kind: .superscript,
                            fields: [
                                TemplateField(id: .base, node: .sequence([.symbol("x")])),
                                TemplateField(id: .exponent, node: .sequence([.symbol("2")]))
                            ]
                        )
                    )
                ])
            ),
            (
                source: .sequence([
                    .template(
                        MathTemplateFormula(
                            kind: .fraction,
                            fields: [
                                .sequence([.symbol("x")]),
                                .sequence([.symbol("y")])
                            ]
                        )
                    )
                ]),
                editorRoot: .sequence([
                    .template(
                        TemplateNode(
                            kind: .fraction,
                            fields: [
                                TemplateField(id: .numerator, node: .sequence([.symbol("x")])),
                                TemplateField(id: .denominator, node: .sequence([.symbol("y")]))
                            ]
                        )
                    )
                ])
            ),
            (
                source: .sequence([
                    .template(
                        MathTemplateFormula(
                            kind: .sqrt,
                            fields: [
                                .sequence([.symbol("y")])
                            ]
                        )
                    )
                ]),
                editorRoot: .sequence([
                    .template(
                        TemplateNode(
                            kind: .sqrt,
                            fields: [
                                TemplateField(id: .radicand, node: .sequence([.symbol("y")]))
                            ]
                        )
                    )
                ])
            ),
            (
                source: .sequence([
                    .template(
                        MathTemplateFormula(
                            kind: .piecewise(rows: 1),
                            fields: [
                                .sequence([.symbol("a")]),
                                .sequence([.symbol("b")])
                            ]
                        )
                    )
                ]),
                editorRoot: .sequence([
                    .template(
                        TemplateNode(
                            kind: .piecewise(rows: 1),
                            fields: [
                                TemplateField(id: .rowExpression(0), node: .sequence([.symbol("a")])),
                                TemplateField(id: .rowCondition(0), node: .sequence([.symbol("b")]))
                            ]
                        )
                    )
                ])
            ),
            (
                source: .sequence([
                    .template(
                        MathTemplateFormula(
                            kind: .parametric2D,
                            fields: [
                                .sequence([.symbol("x")]),
                                .sequence([.symbol("y")]),
                                .sequence([.symbol("t")])
                            ]
                        )
                    )
                ]),
                editorRoot: .sequence([
                    .template(
                        TemplateNode(
                            kind: .parametricEquation2D,
                            fields: [
                                TemplateField(id: .parametricExpression(0), node: .sequence([.symbol("x")])),
                                TemplateField(id: .parametricExpression(1), node: .sequence([.symbol("y")])),
                                TemplateField(id: .parametricRange, node: .sequence([.symbol("t")]))
                            ]
                        )
                    )
                ])
            )
        ]

        for (source, editorRoot) in cases {
            let snapshot = FormulaDisplayBridge.projectionSnapshot(
                source: source,
                includesInsertionMarkers: true
            )
            for (insertionID, cursor) in snapshot.insertionCursors {
                XCTAssertNotNil(
                    MathEditorTree.sequence(at: cursor.path, in: editorRoot),
                    "Insertion \(insertionID.stableStringValue) mapped to invalid path \(cursor)"
                )
                if let sequence = MathEditorTree.sequence(at: cursor.path, in: editorRoot) {
                    XCTAssertTrue(
                        (0...sequence.count).contains(cursor.offset),
                        "Insertion \(insertionID.stableStringValue) mapped to out-of-range offset \(cursor.offset) for sequence count \(sequence.count)"
                    )
                }
            }
        }
    }

    func testBridgeWrapsTemplateFieldsWithInsertionMarkers() {
        let formula = MathFormula.sequence([
            .template(
                MathTemplateFormula(
                    kind: .sqrt,
                    fields: [
                        .symbol("x")
                    ]
                )
            )
        ])

        let document = FormulaDisplayBridge.document(
            source: formula,
            includesInsertionMarkers: true
        )

        guard case .sequence(let rootNodes) = document.root else {
            return XCTFail("Expected root sequence")
        }
        XCTAssertEqual(rootNodes.count, 3)
        guard case .sqrt(let radicand) = rootNodes[1] else {
            return XCTFail("Expected sqrt node")
        }
        guard case .sequence(let radicandNodes) = radicand else {
            return XCTFail("Expected wrapped radicand sequence")
        }
        XCTAssertEqual(radicandNodes.count, 3)
        guard case .insertionMarker(let leading) = radicandNodes[0] else {
            return XCTFail("Expected leading insertion marker in radicand")
        }
        guard case .insertionMarker(let trailing) = radicandNodes[2] else {
            return XCTFail("Expected trailing insertion marker in radicand")
        }
        XCTAssertEqual(leading.id.stableStringValue, "insertion:sequence[0]/field.radicand@0#leading")
        XCTAssertEqual(trailing.id.stableStringValue, "insertion:sequence[0]/field.radicand@1#trailing")
    }
}
