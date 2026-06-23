public struct PiecewiseSampler2D {
    public var evaluator: ExprEvaluator
    public var conditionEvaluator: ConditionEvaluator
    public var options: CurveSamplingOptions2D

    public init(
        evaluator: ExprEvaluator = .init(),
        conditionEvaluator: ConditionEvaluator = .init(),
        options: CurveSamplingOptions2D = .defaults(for: .balanced)
    ) {
        self.evaluator = evaluator
        self.conditionEvaluator = conditionEvaluator
        self.options = options
    }

    public func sampleY(
        branches: [GraphIntentBranch],
        variable: Symbol,
        range: SamplingRange,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        var issues: [SamplingIssue] = []
        var issueKinds = Set<SamplingIssueKind>()

        guard range.lower < range.upper else {
            return SampleSet2D(
                segments: [],
                issues: [SamplingIssue(kind: .invalidRange, message: "range.lower must be < range.upper")]
            )
        }
        guard options.initialSampleCount >= 2 else {
            return SampleSet2D(
                segments: [],
                issues: [SamplingIssue(kind: .insufficientSamples, message: "initialSampleCount must be >= 2")]
            )
        }

        let count = options.initialSampleCount
        let step = (range.upper - range.lower) / Double(count - 1)
        let baseSamples = (0..<count).map { i in
            range.lower + Double(i) * step
        }
        let boundarySamples = extractBoundarySamples(
            branches: branches,
            variable: variable,
            range: range,
            environment: environment
        )
        let xSamples = mergedSampleXs(base: baseSamples, boundaries: boundarySamples)
        var segments: [SampleSegment2D] = []
        var currentPoints: [SamplePoint2D] = []
        var previousPoint: SamplePoint2D?
        var previousBranchIndex: Int?

        for x in xSamples {
            var envValues = environment.values
            envValues[variable] = x
            let env = EvaluationEnvironment(values: envValues)

            let outcome = evaluateAtX(
                x: x,
                branches: branches,
                environment: env,
                expectedVariable: variable,
                issues: &issues,
                issueKinds: &issueKinds
            )

            guard let point = outcome.point else {
                if !currentPoints.isEmpty {
                    segments.append(.init(points: currentPoints))
                    currentPoints = []
                }
                previousPoint = nil
                previousBranchIndex = nil
                continue
            }

            if let prevBranch = previousBranchIndex, prevBranch != outcome.branchIndex {
                if !currentPoints.isEmpty {
                    segments.append(.init(points: currentPoints))
                    currentPoints = []
                }
            } else if let previous = previousPoint,
                      abs(point.y - previous.y) > options.discontinuityThreshold {
                if !currentPoints.isEmpty {
                    segments.append(.init(points: currentPoints))
                    currentPoints = []
                }
                appendIssueOnce(
                    kind: .possibleDiscontinuity,
                    message: "jump detected between (\(previous.x),\(previous.y)) and (\(point.x),\(point.y))",
                    issues: &issues,
                    issueKinds: &issueKinds
                )
            }

            currentPoints.append(point)
            previousPoint = point
            previousBranchIndex = outcome.branchIndex
        }

        if !currentPoints.isEmpty {
            segments.append(.init(points: currentPoints))
        }

        return SampleSet2D(segments: segments, issues: issues)
    }

    private func mergedSampleXs(base: [Double], boundaries: [Double]) -> [Double] {
        var merged = base
        merged.append(contentsOf: boundaries)
        merged.sort()

        var deduped: [Double] = []
        for value in merged {
            if let last = deduped.last, abs(last - value) <= 1e-9 {
                continue
            }
            deduped.append(value)
        }
        return deduped
    }

    private func extractBoundarySamples(
        branches: [GraphIntentBranch],
        variable: Symbol,
        range: SamplingRange,
        environment: EvaluationEnvironment
    ) -> [Double] {
        var values: [Double] = []
        for branch in branches {
            values.append(contentsOf: boundaryValues(from: branch.condition, variable: variable, environment: environment))
        }
        return values.filter { value in
            value.isFinite && value >= range.lower - 1e-9 && value <= range.upper + 1e-9
        }
    }

    private func boundaryValues(
        from condition: Expr,
        variable: Symbol,
        environment: EvaluationEnvironment
    ) -> [Double] {
        switch condition {
        case .relation(let left, _, let right):
            if case .symbol(let symbol) = left, symbol.name == variable.name {
                return evaluatedScalar(right, environment: environment).map { [$0] } ?? []
            }
            if case .symbol(let symbol) = right, symbol.name == variable.name {
                return evaluatedScalar(left, environment: environment).map { [$0] } ?? []
            }
            return []
        case .chainedRelation(let expressions, _):
            guard expressions.count == 3 else { return [] }
            if case .symbol(let symbol) = expressions[1], symbol.name == variable.name {
                var result: [Double] = []
                if let lower = evaluatedScalar(expressions[0], environment: environment) {
                    result.append(lower)
                }
                if let upper = evaluatedScalar(expressions[2], environment: environment) {
                    result.append(upper)
                }
                return result
            }
            return []
        default:
            return []
        }
    }

    private func evaluatedScalar(_ expr: Expr, environment: EvaluationEnvironment) -> Double? {
        switch evaluator.evaluate(expr, environment: environment) {
        case .value(let value):
            return value.isFinite ? value : nil
        case .undefined:
            return nil
        }
    }

    private struct EvaluationOutcome {
        var point: SamplePoint2D?
        var branchIndex: Int?
    }

    private func evaluateAtX(
        x: Double,
        branches: [GraphIntentBranch],
        environment: EvaluationEnvironment,
        expectedVariable: Symbol,
        issues: inout [SamplingIssue],
        issueKinds: inout Set<SamplingIssueKind>
    ) -> EvaluationOutcome {
        for (index, branch) in branches.enumerated() {
            guard case .explicitY(let expression, let variable) = branch.intent else {
                appendIssueOnce(
                    kind: .unsupportedIntent,
                    message: "PiecewiseSampler2D currently supports only explicitY branches.",
                    issues: &issues,
                    issueKinds: &issueKinds
                )
                continue
            }
            guard variable.name == expectedVariable.name else {
                appendIssueOnce(
                    kind: .unsupportedIntent,
                    message: "Piecewise branch variable mismatch: expected \(expectedVariable.name), got \(variable.name).",
                    issues: &issues,
                    issueKinds: &issueKinds
                )
                continue
            }

            let conditionResult = conditionEvaluator.evaluate(branch.condition, environment: environment)
            switch conditionResult {
            case .unsatisfied:
                continue
            case .undefined(let issue):
                appendIssueOnce(
                    kind: .evaluationUndefined,
                    message: "condition undefined at x=\(x): \(issue.kind.rawValue) - \(issue.message)",
                    issues: &issues,
                    issueKinds: &issueKinds
                )
                return .init(point: nil, branchIndex: nil)
            case .satisfied:
                let valueResult = evaluator.evaluate(expression, environment: environment)
                switch valueResult {
                case .undefined(let issue):
                    appendIssueOnce(
                        kind: .evaluationUndefined,
                        message: "value undefined at x=\(x): \(issue.kind.rawValue) - \(issue.message)",
                        issues: &issues,
                        issueKinds: &issueKinds
                    )
                    return .init(point: nil, branchIndex: nil)
                case .value(let y):
                    let point = SamplePoint2D(x: x, y: y)
                    guard point.x.isFinite, point.y.isFinite else {
                        appendIssueOnce(
                            kind: .nonFinitePoint,
                            message: "non-finite sample point at x=\(point.x), y=\(point.y)",
                            issues: &issues,
                            issueKinds: &issueKinds
                        )
                        return .init(point: nil, branchIndex: nil)
                    }
                    guard abs(point.x) <= options.maxAbsCoordinate, abs(point.y) <= options.maxAbsCoordinate else {
                        appendIssueOnce(
                            kind: .nonFinitePoint,
                            message: "sample exceeds maxAbsCoordinate at x=\(point.x), y=\(point.y)",
                            issues: &issues,
                            issueKinds: &issueKinds
                        )
                        return .init(point: nil, branchIndex: nil)
                    }
                    return .init(point: point, branchIndex: index)
                }
            }
        }

        return .init(point: nil, branchIndex: nil)
    }

    private func appendIssueOnce(
        kind: SamplingIssueKind,
        message: String,
        issues: inout [SamplingIssue],
        issueKinds: inout Set<SamplingIssueKind>
    ) {
        guard !issueKinds.contains(kind) else { return }
        issueKinds.insert(kind)
        issues.append(.init(kind: kind, message: message))
    }
}
