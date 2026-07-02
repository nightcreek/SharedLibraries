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

    func testDeferredTemplateProjectsToRawLatexFallback() {
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

        guard case .sequence(let items) = projected,
              items.count == 1,
              case .rawLatex(let value) = items[0] else {
            return XCTFail("Expected rawLatex fallback, got \(projected)")
        }

        XCTAssertTrue(value.contains("\\begin{cases}"))
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
