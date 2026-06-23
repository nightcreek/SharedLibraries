public enum ConditionEvaluationResult: Equatable, Sendable {
    case satisfied
    case unsatisfied
    case undefined(EvaluationIssue)
}
