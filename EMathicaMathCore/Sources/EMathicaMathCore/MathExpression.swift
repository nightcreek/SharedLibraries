import Foundation

public enum SemanticGraphKind: String, Hashable, Codable {
    case explicitY
    case explicitX
    case parametric2D
    case polar
    case point
    case circle
    case ellipse
    case hyperbola
    case parabola
    case conic
    case piecewise
    case implicit
    case unknown
}

public struct MathExpression: Hashable, Codable {
    public var displayText: String
    public var rawInput: String?
    public var normalizedExpression: String?
    public var simplifiedExpression: String?
    public var recognizedShape: RecognizedShapeKind?
    public var plotStrategy: PlotStrategyKind?
    public var rewriteInfo: ParametricRewriteInfo?
    public var restrictions: [String]?
    public var originalLatex: String?
    public var normalizedLatex: String?
    public var simplifiedLatex: String?
    public var simplifiedDisplayText: String?
    public var algebraAnalysis: AlgebraAnalysisResult?
    public var semanticGraphKind: SemanticGraphKind?
    public var semanticParameterSymbol: Symbol?
    public var semanticParameterRange: ParameterRange?
    public var editorASTData: String?
    public var sourceExpression: String?
    public var computeExpression: String?

    public init(
        displayText: String,
        rawInput: String? = nil,
        normalizedExpression: String? = nil,
        simplifiedExpression: String? = nil,
        recognizedShape: RecognizedShapeKind? = nil,
        plotStrategy: PlotStrategyKind? = nil,
        rewriteInfo: ParametricRewriteInfo? = nil,
        restrictions: [String]? = nil,
        originalLatex: String? = nil,
        normalizedLatex: String? = nil,
        simplifiedLatex: String? = nil,
        simplifiedDisplayText: String? = nil,
        algebraAnalysis: AlgebraAnalysisResult? = nil,
        semanticGraphKind: SemanticGraphKind? = nil,
        semanticParameterSymbol: Symbol? = nil,
        semanticParameterRange: ParameterRange? = nil,
        editorASTData: String? = nil,
        sourceExpression: String? = nil,
        computeExpression: String? = nil
    ) {
        self.displayText = displayText
        self.rawInput = rawInput
        self.normalizedExpression = normalizedExpression
        self.simplifiedExpression = simplifiedExpression
        self.recognizedShape = recognizedShape
        self.plotStrategy = plotStrategy
        self.rewriteInfo = rewriteInfo
        self.restrictions = restrictions
        self.originalLatex = originalLatex
        self.normalizedLatex = normalizedLatex
        self.simplifiedLatex = simplifiedLatex
        self.simplifiedDisplayText = simplifiedDisplayText
        self.algebraAnalysis = algebraAnalysis
        self.semanticGraphKind = semanticGraphKind
        self.semanticParameterSymbol = semanticParameterSymbol
        self.semanticParameterRange = semanticParameterRange
        self.editorASTData = editorASTData
        self.sourceExpression = sourceExpression
        self.computeExpression = computeExpression
    }

    public static func algebra(_ analysis: AlgebraAnalysisResult) -> MathExpression {
        MathExpression(
            displayText: analysis.displayText,
            rawInput: analysis.rawInput,
            normalizedExpression: analysis.normalizedExpression,
            simplifiedExpression: analysis.simplifiedExpression,
            recognizedShape: analysis.recognizedShape,
            plotStrategy: analysis.plotStrategy,
            rewriteInfo: analysis.rewriteInfo,
            restrictions: analysis.restrictions,
            originalLatex: analysis.originalLatex,
            normalizedLatex: analysis.normalizedLatex,
            simplifiedLatex: analysis.simplifiedLatex,
            simplifiedDisplayText: analysis.simplifiedDisplayText,
            algebraAnalysis: analysis
        )
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(displayText)
        hasher.combine(rawInput)
        hasher.combine(normalizedExpression)
        hasher.combine(simplifiedExpression)
        hasher.combine(recognizedShape)
        hasher.combine(plotStrategy)
        hasher.combine(rewriteInfo)
        hasher.combine(restrictions)
        hasher.combine(originalLatex)
        hasher.combine(normalizedLatex)
        hasher.combine(simplifiedLatex)
        hasher.combine(simplifiedDisplayText)
        hasher.combine(algebraAnalysis)
        hasher.combine(semanticGraphKind)
        hasher.combine(semanticParameterSymbol)
        hasher.combine(editorASTData)
        hasher.combine(sourceExpression)
        hasher.combine(computeExpression)
    }
}
