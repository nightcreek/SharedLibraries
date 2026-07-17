import EMathicaMathCore
import EMathicaMathInputCore
import CoreGraphics
import Foundation

struct WorkspaceReadOnlyFormulaSource: Equatable {
    var surface: FormulaDisplaySurface
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
        if let editorState {
            rawValue = MathInputProjectionAdapter.displayMarkup(
                from: FormulaInputState(editorState: editorState)
            ).rawValue
        } else {
            rawValue = WorkspaceFormulaMarkupResolver.expressionMarkup(
                displayText: object.expression.displayText,
                originalLatex: object.expression.originalLatex,
                rawInput: object.expression.rawInput
            ) ?? fallbackText
        }

        return .init(
            surface: .objectPanel,
            rawValue: rawValue,
            fallbackText: fallbackText,
            fontSize: fontSize,
            minHeight: minHeight,
            allowsMultiline: allowsMultiline
        )
    }
}

typealias WorkspaceObjectFormulaSource = WorkspaceReadOnlyFormulaSource
