import Foundation

public struct AlgebraAnalysisResult: Hashable, Codable {
    public var rawInput: String?
    public var normalizedExpression: String?
    public var simplifiedExpression: String?
    public var originalLatex: String
    public var normalizedLatex: String
    public var simplifiedLatex: String
    public var displayText: String
    public var simplifiedDisplayText: String
    public var variables: [String]
    public var parameters: [String]
    public var classification: AlgebraClassification
    public var recognizedShape: RecognizedShapeKind?
    public var plotStrategy: PlotStrategyKind?
    public var rewriteInfo: ParametricRewriteInfo?
    public var restrictions: [String]?
    public var unresolvedSymbols: [String]
    public var diagnostics: [AlgebraDiagnostic]
    public var relation: AlgebraRelation
    public var simplifiedRelation: AlgebraRelation
}

public enum RecognizedShapeKind: String, Hashable, Codable {
    case circle
    case ellipse
    case hyperbola
    case parabola
    case superellipse
}

public enum PlotStrategyKind: String, Hashable, Codable {
    case explicitY
    case explicitX
    case horizontalLine
    case verticalLine
    case conicParametric
    case parametric
    case implicit
    case unsupported
}

public struct ParametricRewriteInfo: Hashable, Codable {
    public var shapeKind: RecognizedShapeKind
    public var curve: ParametricCurveDefinition
    public var summary: String
}

public struct ParametricCurveDefinition: Hashable, Codable {
    public enum Kind: String, Hashable, Codable {
        case circle
        case ellipse
        case hyperbolaHorizontal
        case hyperbolaVertical
        case parabolaHorizontal
        case parabolaVertical
        case superellipse
    }

    public var kind: Kind
    public var centerX: Double
    public var centerY: Double
    public var radiusX: Double
    public var radiusY: Double
    public var exponent: Double
    public var radiusXSymbol: String?
    public var radiusYSymbol: String?
    public var exponentSymbol: String?
    public var focalParameter: Double?
    public var tMin: Double
    public var tMax: Double
}

public struct AlgebraDiagnostic: Hashable, Codable {
    public enum Severity: String, Hashable, Codable {
        case info
        case warning
        case error
    }

    public var severity: Severity
    public var message: String
}

public struct AlgebraClassification: Hashable, Codable {
    public enum Kind: String, Hashable, Codable {
        case explicitY
        case explicitX
        case horizontalLine
        case verticalLine
        case circle
        case ellipse
        case superellipse
        case hyperbola
        case parabola
        case implicitPlaneCurve
        case unsupported
    }

    public var kind: Kind
    public var summary: String
    public var renderExpression: AlgebraExpression?
    public var centerX: Double?
    public var centerY: Double?
    public var radius: Double?
    public var radiusX: Double?
    public var radiusY: Double?

    public static func unsupported(_ message: String) -> AlgebraClassification {
        AlgebraClassification(kind: .unsupported, summary: message)
    }
}

public struct AlgebraParseResult: Hashable, Codable {
    public var relation: AlgebraRelation
    public var diagnostics: [AlgebraDiagnostic]
}
