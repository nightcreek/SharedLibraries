import EMathicaMathInputCore
import XCTest
@testable import EMathicaWorkspaceKit

final class FormulaCursorNavigationResolverTests: XCTestCase {
    func testLinearNavigationMovesThroughInsertionAnchorsInSimpleSequence() {
        let editorState = EditorState(
            root: .sequence([
                .character("x"),
                .operatorSymbol("+"),
                .character("y")
            ]),
            cursor: EditorCursor(path: [], offset: 1),
            selection: nil
        )

        XCTAssertEqual(
            FormulaCursorNavigationResolver.resolve(action: .moveLeft, editorState: editorState),
            EditorCursor(path: [], offset: 0)
        )
        XCTAssertEqual(
            FormulaCursorNavigationResolver.resolve(action: .moveRight, editorState: editorState),
            EditorCursor(path: [], offset: 2)
        )
    }

    func testLinearNavigationPreservesSuperscriptBoundaries() {
        let editorState = EditorState(
            root: .sequence([
                .template(
                    TemplateNode(
                        kind: .superscript,
                        fields: [
                            TemplateField(id: .base, node: .sequence([.character("x")])),
                            TemplateField(id: .exponent, node: .sequence([]))
                        ]
                    )
                )
            ]),
            cursor: EditorCursor(
                path: [.sequenceIndex(0), .templateField(.exponent)],
                offset: 0
            ),
            selection: nil
        )

        XCTAssertEqual(
            FormulaCursorNavigationResolver.resolve(action: .moveLeft, editorState: editorState),
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.base)],
                offset: 1
            )
        )
    }

    func testVerticalNavigationUsesTemplateRulesForFractionMatrixCasesAndParametricStructures() {
        let fractionState = EditorState(
            root: .sequence([
                .template(
                    TemplateNode(
                        kind: .fraction,
                        fields: [
                            TemplateField(id: .numerator, node: .sequence([.character("x")])),
                            TemplateField(id: .denominator, node: .sequence([.character("y")]))
                        ]
                    )
                )
            ]),
            cursor: EditorCursor(
                path: [.sequenceIndex(0), .templateField(.numerator)],
                offset: 1
            ),
            selection: nil
        )

        XCTAssertEqual(
            FormulaCursorNavigationResolver.resolve(action: .moveDown, editorState: fractionState),
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.denominator)],
                offset: 1
            )
        )

        let matrixState = EditorState(
            root: .sequence([
                .template(
                    TemplateNode(
                        kind: .matrix(rows: 2, cols: 2),
                        fields: [
                            TemplateField(id: .matrixCell(row: 0, col: 0), node: .sequence([.character("a")])),
                            TemplateField(id: .matrixCell(row: 0, col: 1), node: .sequence([.character("b")])),
                            TemplateField(id: .matrixCell(row: 1, col: 0), node: .sequence([.character("c")])),
                            TemplateField(id: .matrixCell(row: 1, col: 1), node: .sequence([.character("d")]))
                        ]
                    )
                )
            ]),
            cursor: EditorCursor(
                path: [.sequenceIndex(0), .templateField(.matrixCell(row: 0, col: 0))],
                offset: 1
            ),
            selection: nil
        )

        XCTAssertEqual(
            FormulaCursorNavigationResolver.resolve(action: .moveDown, editorState: matrixState),
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.matrixCell(row: 1, col: 0))],
                offset: 1
            )
        )

        let parametricState = EditorState(
            root: .sequence([
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
            ]),
            cursor: EditorCursor(
                path: [.sequenceIndex(0), .templateField(.parametricExpression(0))],
                offset: 1
            ),
            selection: nil
        )

        XCTAssertEqual(
            FormulaCursorNavigationResolver.resolve(action: .moveDown, editorState: parametricState),
            EditorCursor(
                path: [.sequenceIndex(0), .templateField(.parametricExpression(1))],
                offset: 1
            )
        )
    }
}
