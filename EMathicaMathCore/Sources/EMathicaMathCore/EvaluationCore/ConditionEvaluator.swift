import Foundation

public struct ConditionEvaluator {
    public var evaluator: ExprEvaluator
    public var options: EvaluationOptions

    public init(
        evaluator: ExprEvaluator = .init(),
        options: EvaluationOptions = .init()
    ) {
        self.evaluator = evaluator
        self.options = options
    }

    public func evaluate(
        _ condition: Expr,
        environment: EvaluationEnvironment
    ) -> ConditionEvaluationResult {
        switch condition {
        case .relation(let left, let relation, let right):
            return evaluateRelation(left: left, relation: relation, right: right, environment: environment)
        case .equation(let left, let right):
            return evaluateRelation(left: left, relation: .equal, right: right, environment: environment)
        case .chainedRelation(let expressions, let relations):
            return evaluateChained(expressions: expressions, relations: relations, environment: environment)
        default:
            return .undefined(issue(.unsupportedExpression, "condition is not relation/equation/chainedRelation"))
        }
    }

    private func evaluateChained(
        expressions: [Expr],
        relations: [RelationOperator],
        environment: EvaluationEnvironment
    ) -> ConditionEvaluationResult {
        guard expressions.count >= 2, relations.count == expressions.count - 1 else {
            return .undefined(issue(.unsupportedExpression, "invalid chained relation structure"))
        }

        for index in 0..<relations.count {
            let result = evaluateRelation(
                left: expressions[index],
                relation: relations[index],
                right: expressions[index + 1],
                environment: environment
            )
            switch result {
            case .satisfied:
                continue
            case .unsatisfied:
                return .unsatisfied
            case .undefined(let err):
                return .undefined(err)
            }
        }
        return .satisfied
    }

    private func evaluateRelation(
        left: Expr,
        relation: RelationOperator,
        right: Expr,
        environment: EvaluationEnvironment
    ) -> ConditionEvaluationResult {
        let leftResult = evaluator.evaluate(left, environment: environment)
        let rightResult = evaluator.evaluate(right, environment: environment)

        let leftValue: Double
        let rightValue: Double

        switch (leftResult, rightResult) {
        case (.undefined(let err), _):
            return .undefined(err)
        case (_, .undefined(let err)):
            return .undefined(err)
        case (.value(let l), .value(let r)):
            leftValue = l
            rightValue = r
        }

        let delta = leftValue - rightValue
        let epsilon = options.epsilon
        let satisfied: Bool

        switch relation {
        case .less:
            satisfied = leftValue < rightValue
        case .lessOrEqual:
            satisfied = leftValue <= rightValue + epsilon
        case .greater:
            satisfied = leftValue > rightValue
        case .greaterOrEqual:
            satisfied = leftValue + epsilon >= rightValue
        case .equal:
            satisfied = abs(delta) <= epsilon
        case .notEqual:
            satisfied = abs(delta) > epsilon
        case .approximatelyEqual:
            satisfied = abs(delta) <= epsilon
        }

        return satisfied ? .satisfied : .unsatisfied
    }

    private func issue(_ kind: EvaluationIssueKind, _ message: String) -> EvaluationIssue {
        EvaluationIssue(kind: kind, message: message)
    }
}
