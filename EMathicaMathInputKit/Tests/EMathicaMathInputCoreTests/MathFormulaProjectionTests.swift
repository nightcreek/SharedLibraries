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
                        kind: .piecewise2,
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

    func testAdditionalUnsupportedTemplatesUseStableRawLatexFallback() {
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
        XCTAssertEqual(items[0], .rawLatex(#"\sqrt[3]{x}"#))
        XCTAssertEqual(items[1], .rawLatex("a_{1}^{2}"))

        guard case .rawLatex(let matrixLatex) = items[2] else {
            return XCTFail("Expected matrix fallback, got \(items[2])")
        }
        XCTAssertTrue(matrixLatex.contains(#"\begin{pmatrix}"#))
        XCTAssertTrue(matrixLatex.contains("x&y"))
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
}
