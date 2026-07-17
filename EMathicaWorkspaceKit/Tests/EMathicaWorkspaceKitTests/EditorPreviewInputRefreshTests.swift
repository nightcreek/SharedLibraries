import EMathicaMathInputCore
import XCTest
@testable import EMathicaWorkspaceKit

@MainActor
final class EditorPreviewInputRefreshTests: XCTestCase {
    func testPreviewRefreshTracksMarkupChangesWithoutMutatingInputState() {
        let states = [
            makeState(root: .sequence([.character("x")]), cursorOffset: 1),
            makeState(
                root: .sequence([
                    .template(
                        TemplateNode(
                            kind: .superscript,
                            fields: [
                                .init(id: .base, node: .sequence([.character("x")])),
                                .init(id: .exponent, node: .sequence([.character("2")]))
                            ]
                        )
                    )
                ]),
                cursorOffset: 1
            ),
            makeState(
                root: .sequence([
                    .template(
                        TemplateNode(
                            kind: .superscript,
                            fields: [
                                .init(id: .base, node: .sequence([.character("x")])),
                                .init(id: .exponent, node: .sequence([.character("2")]))
                            ]
                        )
                    ),
                    .operatorSymbol("+"),
                    .character("1")
                ]),
                cursorOffset: 3
            ),
            makeState(
                root: .sequence([
                    .template(
                        TemplateNode(
                            kind: .fraction,
                            fields: [
                                .init(
                                    id: .numerator,
                                    node: .sequence([
                                        .template(
                                            TemplateNode(
                                                kind: .superscript,
                                                fields: [
                                                    .init(id: .base, node: .sequence([.character("x")])),
                                                    .init(id: .exponent, node: .sequence([.character("2")]))
                                                ]
                                            )
                                        ),
                                        .operatorSymbol("+"),
                                        .character("1")
                                    ])
                                ),
                                .init(id: .denominator, node: .sequence([.character("2")]))
                            ]
                        )
                    )
                ]),
                cursorOffset: 1
            )
        ]

        let expectedMarkups = [
            #"x\cursor{}"#,
            #"x^{2}\cursor{}"#,
            #"x^{2}+1\cursor{}"#,
            #"\frac{x^{2}+1}{2}\cursor{}"#
        ]

        var observedMarkups: [String] = []
        for state in states {
            let before = state
            let view = FormulaDisplayPreviewView(
                inputState: state,
                configuration: .init(backend: .swiftMath, fontRole: .standard),
                surface: .editorPreview
            )

            XCTAssertNotNil(view)
            XCTAssertEqual(state, before)
            XCTAssertEqual(state.editorState.selection, before.editorState.selection)
            XCTAssertEqual(state.editorState.cursor, before.editorState.cursor)
            observedMarkups.append(state.displayMarkupSnapshot.rawValue)
        }

        XCTAssertEqual(observedMarkups, expectedMarkups)
    }

    private func makeState(root: MathNode, cursorOffset: Int) -> FormulaInputState {
        FormulaInputState(
            editorState: EditorState(
                root: root,
                cursor: .init(path: [], offset: cursorOffset),
                selection: nil
            )
        )
    }
}
