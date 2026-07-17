import EMathicaMathCore
import EMathicaFormulaDisplayCore
import EMathicaMathInputCore
import CoreGraphics
import Foundation

struct WorkspaceReadOnlyFormulaSource: Equatable {
    var surface: FormulaDisplaySurface
    var document: FormulaDisplayDocument?
    var rawValue: String
    var fallbackText: String
    var fontSize: CGFloat
    var minHeight: CGFloat
    var allowsMultiline: Bool

    static func make(
        surface: FormulaDisplaySurface,
        rawValue: String,
        fallbackText: String,
        fontSize: CGFloat,
        minHeight: CGFloat,
        allowsMultiline: Bool
    ) -> WorkspaceReadOnlyFormulaSource {
        .init(
            surface: surface,
            document: nil,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline
        )
    }

    static func make(for object: MathObject) -> WorkspaceReadOnlyFormulaSource {
        let fallbackText = WorkspaceObjectExpressionDisplayResolver.primaryText(for: object)
        let editorState = WorkspaceObjectExpressionDisplayResolver.editorState(for: object)
        let allowsMultiline = WorkspaceObjectRowLayoutMetrics.allowsMultilineFormula(
            semanticGraphKind: object.expression.semanticGraphKind,
            editorState: editorState,
            fallbackText: fallbackText
        )
        let fontSize: CGFloat = allowsMultiline ? 12 : 13
        let minHeight = WorkspaceObjectRowLayoutMetrics.formulaMinHeight(
            semanticGraphKind: object.expression.semanticGraphKind,
            editorState: editorState,
            fallbackText: fallbackText
        )

        let rawValue: String
        let document: FormulaDisplayDocument?
        if let editorState {
            let inputState = FormulaInputState(editorState: editorState)
            document = MathInputProjectionAdapter.displayDocument(from: inputState)
            rawValue = MathInputProjectionAdapter.displayMarkup(from: inputState).rawValue
        } else {
            document = nil
            rawValue = WorkspaceFormulaMarkupResolver.expressionMarkup(
                displayText: object.expression.displayText,
                originalLatex: object.expression.originalLatex,
                rawInput: object.expression.rawInput
            ) ?? fallbackText
        }

        return .init(
            surface: .objectPanel,
            document: document,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline
        )
    }
}

typealias WorkspaceObjectFormulaSource = WorkspaceReadOnlyFormulaSource
