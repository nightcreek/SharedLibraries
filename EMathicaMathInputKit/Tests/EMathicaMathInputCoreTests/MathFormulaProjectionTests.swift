import XCTest
@testable import EMathicaMathInputCore

final class MathFormulaProjectionTests: XCTestCase {
    func testDigitCharactersProjectToNumberFormula() {
        let root = MathNode.sequence([
            .character("1"),
            .character("2"),
            .character("3")
        ])

        let projected = MathFormulaProjection.project(root)

        XCTAssertEqual(projected, .sequence([.number("123")]))
    }

    func testVariableCharactersProjectToSymbolFormula() {
        let root = MathNode.sequence([
            .character("x")
        ])

        let projected = MathFormulaProjection.project(root)

        XCTAssertEqual(projected, .sequence([.symbol("x")]))
    }

    func testOperatorNodesProjectToOperatorFormula() {
        let root = MathNode.sequence([
            .operatorSymbol("+")
        ])

        let projected = MathFormulaProjection.project(root)

        XCTAssertEqual(projected, .sequence([.operatorSymbol("+")]))
    }

    func testFunctionTemplateProjectsToFunctionFormula() {
        let root = MathNode.sequence([
            .template(
                TemplateNode(
                    kind: .sin,
                    fields: [
                        TemplateField(id: .argument, node: .sequence([.character("x")]))
                    ]
                )
            )
        ])

        let projected = MathFormulaProjection.project(root)

        XCTAssertEqual(
            projected,
            .sequence([
                .function(
                    MathFunctionFormula(
                        name: "sin",
                        arguments: [
                            .sequence([.symbol("x")])
                        ]
                    )
                )
            ])
        )
    }

    func testFirstVersionTemplatesProjectToTemplateFormula() {
        let root = MathNode.sequence([
            .template(
                TemplateNode(
                    kind: .fraction,
                    fields: [
                        TemplateField(id: .numerator, node: .sequence([.character("x")])),
                        TemplateField(id: .denominator, node: .sequence([.character("2")]))
                    ]
                )
            ),
            .template(
                TemplateNode(
                    kind: .sqrt,
                    fields: [
                        TemplateField(id: .radicand, node: .sequence([.character("y")]))
                    ]
                )
            ),
            .template(
                TemplateNode(
                    kind: .superscript,
                    fields: [
                        TemplateField(id: .base, node: .sequence([.character("x")])),
                        TemplateField(id: .exponent, node: .sequence([.character("2")]))
                    ]
                )
            ),
            .template(
                TemplateNode(
                    kind: .subscriptTemplate,
                    fields: [
                        TemplateField(id: .base, node: .sequence([.character("a")])),
                        TemplateField(id: .subscriptField, node: .sequence([.character("1")]))
                    ]
                )
            ),
            .template(
                TemplateNode(
                    kind: .parentheses,
                    fields: [
                        TemplateField(id: .content, node: .sequence([.character("z")]))
                    ]
                )
            ),
            .template(
                TemplateNode(
                    kind: .absoluteValue,
                    fields: [
                        TemplateField(id: .content, node: .sequence([.character("w")]))
                    ]
                )
            )
        ])

        let projected = MathFormulaProjection.project(root)

        XCTAssertEqual(
            projected,
            .sequence([
                .template(.init(kind: .fraction, fields: [.sequence([.symbol("x")]), .sequence([.number("2")])])),
                .template(.init(kind: .sqrt, fields: [.sequence([.symbol("y")])])),
                .template(.init(kind: .superscript, fields: [.sequence([.symbol("x")]), .sequence([.number("2")])])),
                .template(.init(kind: .`subscript`, fields: [.sequence([.symbol("a")]), .sequence([.number("1")])])),
                .template(.init(kind: .parentheses, fields: [.sequence([.symbol("z")])])),
                .template(.init(kind: .absoluteValue, fields: [.sequence([.symbol("w")])]))
            ])
        )
    }

    func testPiecewiseTemplateProjectsToStructuredFormula() {
        let root = MathNode.sequence([
            .template(
                TemplateNode(
                    kind: .piecewise(rows: 2),
                    fields: [
                        TemplateField(id: .rowExpression(0), node: .sequence([.character("x")])),
                        TemplateField(id: .rowCondition(0), node: .sequence([.character("x")])),
                        TemplateField(id: .rowExpression(1), node: .sequence([.character("y")])),
                        TemplateField(id: .rowCondition(1), node: .sequence([.character("y")]))
                    ]
                )
            )
        ])

        let projected = MathFormulaProjection.project(root)

        XCTAssertEqual(
            projected,
            .sequence([
                .template(
                    .init(
                        kind: .piecewise(rows: 2),
                        fields: [
                            .sequence([.symbol("x")]),
                            .sequence([.symbol("x")]),
                            .sequence([.symbol("y")]),
                            .sequence([.symbol("y")])
                        ]
                    )
                )
            ])
        )
    }

    func testParametricTemplateProjectsToStructuredFormula() {
        let root = MathNode.sequence([
            .template(
                TemplateNode(
                    kind: .parametricEquation2D,
                    fields: [
                        TemplateField(id: .parametricExpression(0), node: .sequence([.character("x")])),
                        TemplateField(id: .parametricExpression(1), node: .sequence([.character("y")])),
                        TemplateField(id: .parametricRange, node: .sequence([.character("t")]))
                    ]
                )
            )
        ])

        let projected = MathFormulaProjection.project(root)

        XCTAssertEqual(
            projected,
            .sequence([
                .template(
                    .init(
                        kind: .parametric2D,
                        fields: [
                            .sequence([.symbol("x")]),
                            .sequence([.symbol("y")]),
                            .sequence([.symbol("t")])
                        ]
                    )
                )
            ])
        )
    }

    func testAdditionalTemplatesProjectToStructuredFormula() {
        let root = MathNode.sequence([
            .template(
                TemplateNode(
                    kind: .nthRoot,
                    fields: [
                        TemplateField(id: .rootIndex, node: .sequence([.character("3")])),
                        TemplateField(id: .radicand, node: .sequence([.character("x")]))
                    ]
                )
            ),
            .template(
                TemplateNode(
                    kind: .subscriptSuperscript,
                    fields: [
                        TemplateField(id: .base, node: .sequence([.character("a")])),
                        TemplateField(id: .subscriptField, node: .sequence([.character("1")])),
                        TemplateField(id: .exponent, node: .sequence([.character("2")]))
                    ]
                )
            ),
            .template(
                TemplateNode(
                    kind: .matrix(rows: 1, cols: 2),
                    fields: [
                        TemplateField(id: .matrixCell(row: 0, col: 0), node: .sequence([.character("x")])),
                        TemplateField(id: .matrixCell(row: 0, col: 1), node: .sequence([.character("y")]))
                    ]
                )
            )
        ])

        guard case .sequence(let items) = MathFormulaProjection.project(root) else {
            return XCTFail("Expected projected sequence")
        }

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(
            items[0],
            .template(
                .init(
                    kind: .nthRoot,
                    fields: [
                        .sequence([.number("3")]),
                        .sequence([.symbol("x")])
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[1],
            .template(
                .init(
                    kind: .subscriptSuperscript,
                    fields: [
                        .sequence([.symbol("a")]),
                        .sequence([.number("1")]),
                        .sequence([.number("2")])
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[2],
            .template(
                .init(
                    kind: .matrix(rows: 1, cols: 2),
                    fields: [
                        .sequence([.symbol("x")]),
                        .sequence([.symbol("y")])
                    ]
                )
            )
        )
    }

    func testSessionFormulaReflectsStructuredProjection() {
        let session = MathInputSession()

        session.apply(.insertCharacter("x"))
        session.apply(.insertTemplate(.superscript))
        session.apply(.insertCharacter("2"))

        let formula = session.formula()

        XCTAssertEqual(
            formula,
            .sequence([
                .template(
                    MathTemplateFormula(
                        kind: .superscript,
                        fields: [
                            .sequence([.symbol("x")]),
                            .sequence([.number("2")])
                        ]
                    )
                )
            ])
        )
    }

    func testProjectionPreservesNestedTemplatesWhenInnerFieldsAreEmpty() {
        let root = MathNode.sequence([
            sqrtNode(.placeholder),
            absoluteValueNode(sqrtNode(.placeholder)),
            fractionNode(sqrtNode(.placeholder), .symbol("y")),
            superscriptNode(.symbol("x"), sqrtNode(.placeholder)),
            functionNode(.sin, sqrtNode(.placeholder)),
            sqrtNode(fractionNode(.placeholder, .symbol("y")))
        ])

        guard case .sequence(let items) = MathFormulaProjection.project(root) else {
            return XCTFail("Expected projected sequence")
        }

        XCTAssertEqual(
            items[0],
            .template(.init(kind: .sqrt, fields: [.sequence([])]))
        )
        XCTAssertEqual(
            items[1],
            .template(
                .init(
                    kind: .absoluteValue,
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])]))
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[2],
            .template(
                .init(
                    kind: .fraction,
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])])),
                        .symbol("y")
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[3],
            .template(
                .init(
                    kind: .superscript,
                    fields: [
                        .symbol("x"),
                        .template(.init(kind: .sqrt, fields: [.sequence([])]))
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[4],
            .function(
                .init(
                    name: "sin",
                    arguments: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])]))
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[5],
            .template(
                .init(
                    kind: .sqrt,
                    fields: [
                        .template(
                            .init(
                                kind: .fraction,
                                fields: [
                                    .sequence([]),
                                    .symbol("y")
                                ]
                            )
                        )
                    ]
                )
            )
        )
    }

    func testProjectionPreservesWrappedNestedTemplatesWhenFieldContentIsSequenceContainingTemplate() {
        let root = MathNode.sequence([
            absoluteValueNode(wrapped(sqrtNode(.placeholder))),
            fractionNode(wrapped(sqrtNode(.placeholder)), wrapped(.symbol("y"))),
            superscriptNode(wrapped(.symbol("x")), wrapped(sqrtNode(.placeholder))),
            functionNode(.sin, wrapped(sqrtNode(.placeholder))),
            sqrtNode(wrapped(fractionNode(.placeholder, wrapped(.symbol("y")))))
        ])

        guard case .sequence(let items) = MathFormulaProjection.project(root) else {
            return XCTFail("Expected projected sequence")
        }

        XCTAssertEqual(
            items[0],
            .template(
                .init(
                    kind: .absoluteValue,
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])]))
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[1],
            .template(
                .init(
                    kind: .fraction,
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])])),
                        .sequence([.symbol("y")])
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[2],
            .template(
                .init(
                    kind: .superscript,
                    fields: [
                        .sequence([.symbol("x")]),
                        .template(.init(kind: .sqrt, fields: [.sequence([])]))
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[3],
            .function(
                .init(
                    name: "sin",
                    arguments: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])]))
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[4],
            .template(
                .init(
                    kind: .sqrt,
                    fields: [
                        .template(
                            .init(
                                kind: .fraction,
                                fields: [
                                    .sequence([]),
                                    .sequence([.symbol("y")])
                                ]
                            )
                        )
                    ]
                )
            )
        )
    }

    func testProjectionPreservesNestedEmptyTemplatesInsideContainers() {
        let root = MathNode.sequence([
            matrixNode(rows: 1, cols: 2, [
                sqrtNode(.placeholder),
                .symbol("y")
            ]),
            casesNode([
                sqrtNode(.placeholder),
                fractionNode(.symbol("x"), .symbol("y"))
            ]),
            piecewiseNode(rows: 2, fields: [
                .rowExpression(0): .symbol("x"),
                .rowCondition(0): sqrtNode(.placeholder),
                .rowExpression(1): fractionNode(.placeholder, .symbol("y")),
                .rowCondition(1): .symbol("z")
            ])
        ])

        guard case .sequence(let items) = MathFormulaProjection.project(root) else {
            return XCTFail("Expected projected sequence")
        }

        XCTAssertEqual(
            items[0],
            .template(
                .init(
                    kind: .matrix(rows: 1, cols: 2),
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])])),
                        .symbol("y")
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[1],
            .template(
                .init(
                    kind: .cases(rows: 2),
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])])),
                        .template(.init(kind: .fraction, fields: [.symbol("x"), .symbol("y")]))
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[2],
            .template(
                .init(
                    kind: .piecewise(rows: 2),
                    fields: [
                        .symbol("x"),
                        .template(.init(kind: .sqrt, fields: [.sequence([])])),
                        .template(.init(kind: .fraction, fields: [.sequence([]), .symbol("y")])),
                        .symbol("z")
                    ]
                )
            )
        )
    }

    func testProjectionPreservesWrappedNestedTemplatesInsideContainersAndParametricFields() {
        let root = MathNode.sequence([
            matrixNode(rows: 1, cols: 2, [
                wrapped(sqrtNode(.placeholder)),
                wrapped(.symbol("y"))
            ]),
            piecewiseNode(rows: 2, fields: [
                .rowExpression(0): wrapped(.symbol("x")),
                .rowCondition(0): wrapped(absoluteValueNode(.placeholder)),
                .rowExpression(1): wrapped(fractionNode(.placeholder, wrapped(.symbol("y")))),
                .rowCondition(1): wrapped(.symbol("z"))
            ]),
            .template(
                TemplateNode(
                    kind: .parametricEquation2D,
                    fields: [
                        TemplateField(id: .parametricExpression(0), node: wrapped(sqrtNode(.placeholder))),
                        TemplateField(id: .parametricExpression(1), node: wrapped(.symbol("y"))),
                        TemplateField(id: .parametricRange, node: wrapped(.symbol("t")))
                    ]
                )
            )
        ])

        guard case .sequence(let items) = MathFormulaProjection.project(root) else {
            return XCTFail("Expected projected sequence")
        }

        XCTAssertEqual(
            items[0],
            .template(
                .init(
                    kind: .matrix(rows: 1, cols: 2),
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])])),
                        .sequence([.symbol("y")])
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[1],
            .template(
                .init(
                    kind: .piecewise(rows: 2),
                    fields: [
                        .sequence([.symbol("x")]),
                        .template(.init(kind: .absoluteValue, fields: [.sequence([])])),
                        .template(.init(kind: .fraction, fields: [.sequence([]), .sequence([.symbol("y")])])),
                        .sequence([.symbol("z")])
                    ]
                )
            )
        )
        XCTAssertEqual(
            items[2],
            .template(
                .init(
                    kind: .parametric2D,
                    fields: [
                        .template(.init(kind: .sqrt, fields: [.sequence([])])),
                        .sequence([.symbol("y")]),
                        .sequence([.symbol("t")])
                    ]
                )
            )
        )
    }

    private func sqrtNode(_ radicand: MathNode) -> MathNode {
        .template(
            TemplateNode(
                kind: .sqrt,
                fields: [
                    TemplateField(id: .radicand, node: radicand)
                ]
            )
        )
    }

    private func fractionNode(_ numerator: MathNode, _ denominator: MathNode) -> MathNode {
        .template(
            TemplateNode(
                kind: .fraction,
                fields: [
                    TemplateField(id: .numerator, node: numerator),
                    TemplateField(id: .denominator, node: denominator)
                ]
            )
        )
    }

    private func absoluteValueNode(_ content: MathNode) -> MathNode {
        .template(
            TemplateNode(
                kind: .absoluteValue,
                fields: [
                    TemplateField(id: .content, node: content)
                ]
            )
        )
    }

    private func superscriptNode(_ base: MathNode, _ exponent: MathNode) -> MathNode {
        .template(
            TemplateNode(
                kind: .superscript,
                fields: [
                    TemplateField(id: .base, node: base),
                    TemplateField(id: .exponent, node: exponent)
                ]
            )
        )
    }

    private func functionNode(_ kind: TemplateKind, _ argument: MathNode) -> MathNode {
        .template(
            TemplateNode(
                kind: kind,
                fields: [
                    TemplateField(id: .argument, node: argument)
                ]
            )
        )
    }

    private func matrixNode(rows: Int, cols: Int, _ cells: [MathNode]) -> MathNode {
        .template(
            TemplateNode(
                kind: .matrix(rows: rows, cols: cols),
                fields: cells.enumerated().map { index, node in
                    let row = index / cols
                    let col = index % cols
                    return TemplateField(id: .matrixCell(row: row, col: col), node: node)
                }
            )
        )
    }

    private func casesNode(_ expressions: [MathNode]) -> MathNode {
        .template(
            TemplateNode(
                kind: .cases(rows: expressions.count),
                fields: expressions.enumerated().map { index, node in
                    TemplateField(id: .rowExpression(index), node: node)
                }
            )
        )
    }

    private func piecewiseNode(rows: Int, fields: [FieldID: MathNode]) -> MathNode {
        .template(
            TemplateNode(
                kind: .piecewise(rows: rows),
                fields: fields.map { TemplateField(id: $0.key, node: $0.value) }
                    .sorted { lhs, rhs in
                        String(describing: lhs.id) < String(describing: rhs.id)
                    }
            )
        )
    }

    private func wrapped(_ node: MathNode) -> MathNode {
        .sequence([node])
    }
}
