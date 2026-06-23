import EMathicaMathInputCore
import EMathicaMathCore
import Foundation

public enum FormulaPreviewFormatter {
    public static func previewSource(for state: FormulaInputState) -> String {
        state.displayLatex
    }

    public static func previewSource(for source: String) -> String {
        let renderer = LatexMathRenderer()
        let root = MathNode.sequence(source.map { .character(String($0)) })
        return renderer.renderLatex(root, editing: true)
    }

    public static func displayPreview(for state: FormulaInputState, existingObjects: [MathObject]) -> String {
        let preview = state.displayLatex
        if !preview.isEmpty {
            return preview
        }
        return ParameterSuggestionAnalyzer.analyze(state.source, existingObjects: existingObjects).preview
    }
}
