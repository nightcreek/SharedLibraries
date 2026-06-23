public enum EvaluationResult: Equatable, Sendable {
    case value(Double)
    case undefined(EvaluationIssue)
}

public struct EvaluationIssue: Equatable, Sendable {
    public var kind: EvaluationIssueKind
    public var message: String

    public init(kind: EvaluationIssueKind, message: String) {
        self.kind = kind
        self.message = message
    }
}

public enum EvaluationIssueKind: String, Equatable, Sendable {
    case missingVariable
    case divisionByZero
    case squareRootOfNegative
    case logarithmOfNonPositive
    case tangentUndefined
    case invalidPower
    case ambiguousLogBase
    case invalidLogBase
    case unsupportedExpression
    case nonFiniteResult
}
