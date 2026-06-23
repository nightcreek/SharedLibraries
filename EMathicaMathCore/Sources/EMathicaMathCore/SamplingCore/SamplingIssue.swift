public struct SamplingIssue: Equatable, Sendable {
    public var kind: SamplingIssueKind
    public var message: String

    public init(kind: SamplingIssueKind, message: String) {
        self.kind = kind
        self.message = message
    }
}

public enum SamplingIssueKind: String, Equatable, Sendable {
    case invalidRange
    case insufficientSamples
    case evaluationUndefined
    case nonFinitePoint
    case possibleDiscontinuity
    case unsupportedIntent
}
