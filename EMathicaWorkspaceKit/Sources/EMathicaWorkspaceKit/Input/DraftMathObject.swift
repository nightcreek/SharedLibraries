import EMathicaMathInputCore
import EMathicaMathCore
import Foundation

public struct DraftMathObject: Hashable {
    public init(ast: EditorState, sourceExpression: String, displayLatex: String, computeExpression: String, parseError: String?, previewSamples: [PlotSegment], lastValidPreviewSamples: [PlotSegment], algebraAnalysis: AlgebraAnalysisResult?, diagnostics: [FormulaPlotDiagnostic]) { self.ast = ast; self.sourceExpression = sourceExpression; self.displayLatex = displayLatex; self.computeExpression = computeExpression; self.parseError = parseError; self.previewSamples = previewSamples; self.lastValidPreviewSamples = lastValidPreviewSamples; self.algebraAnalysis = algebraAnalysis; self.diagnostics = diagnostics }
    public var ast: EditorState
    public var sourceExpression: String
    public var displayLatex: String
    public var computeExpression: String
    public var parseError: String?
    public var previewSamples: [PlotSegment]
    public var lastValidPreviewSamples: [PlotSegment]
    public var algebraAnalysis: AlgebraAnalysisResult?
    public var diagnostics: [FormulaPlotDiagnostic]

    public static var empty: DraftMathObject {
        DraftMathObject(
            ast: EditorState(),
            sourceExpression: "",
            displayLatex: "",
            computeExpression: "",
            parseError: nil,
            previewSamples: [],
            lastValidPreviewSamples: [],
            algebraAnalysis: nil,
            diagnostics: []
        )
    }
}
