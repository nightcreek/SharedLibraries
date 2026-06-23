import Foundation

public struct ParametricCurveSampler2D {
    public var evaluator: ExprEvaluator
    public var options: CurveSamplingOptions2D

    public init(
        evaluator: ExprEvaluator = .init(),
        options: CurveSamplingOptions2D = .defaults(for: .balanced)
    ) {
        self.evaluator = evaluator
        self.options = options
    }

    public func sample(
        xExpression: Expr,
        yExpression: Expr,
        parameter: Symbol,
        range: SamplingRange,
        viewport: SamplingViewport2D? = nil,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        var issues: [SamplingIssue] = []
        var segments: [SampleSegment2D] = []

        guard range.lower < range.upper else {
            issues.append(.init(kind: .invalidRange, message: "range.lower must be < range.upper"))
            return SampleSet2D(segments: [], issues: issues)
        }
        guard options.initialSampleCount >= 2 else {
            issues.append(.init(kind: .insufficientSamples, message: "initialSampleCount must be >= 2"))
            return SampleSet2D(segments: [], issues: issues)
        }

        let count = options.initialSampleCount
        let step = (range.upper - range.lower) / Double(count - 1)
        var currentPoints: [SamplePoint2D] = []
        var previousPoint: SamplePoint2D?
        var producedPoints = 0

        let refinementMode: RefinementMode
        switch options.algorithm {
        case .uniform:
            refinementMode = .none
        case .uniformWithBasicRefinement:
            refinementMode = .basic
        case .adaptiveScreenSpace:
            if let viewport, let tolerance = options.screenErrorTolerance {
                refinementMode = .screen(viewport: viewport, tolerance: tolerance)
            } else {
                refinementMode = .basic
            }
        case .hybridExploratory:
            if let viewport, let tolerance = options.screenErrorTolerance {
                // Hybrid exploratory fallback: full high-frequency probing/domain hints are future work.
                refinementMode = .screen(viewport: viewport, tolerance: tolerance)
            } else {
                refinementMode = .basic
            }
        }

        for i in 0..<count {
            let t = range.lower + Double(i) * step
            let outcome = evaluatePoint(
                t: t,
                xExpression: xExpression,
                yExpression: yExpression,
                parameter: parameter,
                baseEnvironment: environment
            )
            issues.append(contentsOf: outcome.issues)

            guard let point = outcome.point else {
                if !currentPoints.isEmpty {
                    segments.append(.init(points: currentPoints))
                    currentPoints = []
                }
                previousPoint = nil
                continue
            }

            if let previous = previousPoint {
                if jumpDistance(previous, point) > options.discontinuityThreshold {
                    if !currentPoints.isEmpty {
                        segments.append(.init(points: currentPoints))
                        currentPoints = []
                    }
                    issues.append(.init(
                        kind: .possibleDiscontinuity,
                        message: "jump detected between (\(previous.x),\(previous.y)) and (\(point.x),\(point.y))"
                    ))
                } else if shouldRefine(refinementMode) {
                    let refined = refineBetween(
                        left: previous,
                        leftT: t - step,
                        right: point,
                        rightT: t,
                        depth: 0,
                        xExpression: xExpression,
                        yExpression: yExpression,
                        parameter: parameter,
                        baseEnvironment: environment,
                        refinementMode: refinementMode,
                        producedPoints: &producedPoints,
                        issues: &issues
                    )
                    if let refinedPoints = refined {
                        if !currentPoints.isEmpty {
                            currentPoints.removeLast()
                        }
                        currentPoints.append(contentsOf: refinedPoints)
                        previousPoint = currentPoints.last
                        continue
                    }
                }
            }

            currentPoints.append(point)
            producedPoints += 1
            previousPoint = point
        }

        if !currentPoints.isEmpty {
            segments.append(.init(points: currentPoints))
        }
        return SampleSet2D(segments: segments, issues: issues)
    }

    private enum RefinementMode {
        case none
        case basic
        case screen(viewport: SamplingViewport2D, tolerance: Double)
    }

    private struct SampleOutcome {
        var point: SamplePoint2D?
        var issues: [SamplingIssue]
    }

    private func refineBetween(
        left: SamplePoint2D,
        leftT: Double,
        right: SamplePoint2D,
        rightT: Double,
        depth: Int,
        xExpression: Expr,
        yExpression: Expr,
        parameter: Symbol,
        baseEnvironment: EvaluationEnvironment,
        refinementMode: RefinementMode,
        producedPoints: inout Int,
        issues: inout [SamplingIssue]
    ) -> [SamplePoint2D]? {
        guard depth < options.maxRefinementDepth else {
            return [left, right]
        }
        guard producedPoints < options.maxSampleCount else {
            return [left, right]
        }

        let midT = (leftT + rightT) / 2.0
        let midOutcome = evaluatePoint(
            t: midT,
            xExpression: xExpression,
            yExpression: yExpression,
            parameter: parameter,
            baseEnvironment: baseEnvironment
        )
        issues.append(contentsOf: midOutcome.issues)

        guard let mid = midOutcome.point else {
            return nil
        }

        if jumpDistance(left, mid) > options.discontinuityThreshold || jumpDistance(mid, right) > options.discontinuityThreshold {
            issues.append(.init(
                kind: .possibleDiscontinuity,
                message: "refinement jump detected near midpoint (\(mid.x),\(mid.y))"
            ))
            return nil
        }

        let error: Double
        let threshold: Double
        switch refinementMode {
        case .none:
            return [left, right]
        case .basic:
            let linearMid = SamplePoint2D(
                x: (left.x + right.x) / 2.0,
                y: (left.y + right.y) / 2.0
            )
            error = jumpDistance(mid, linearMid)
            threshold = options.refinementErrorThreshold
        case .screen(let viewport, let tolerance):
            let screenLeft = viewport.project(left)
            let screenRight = viewport.project(right)
            let screenMid = viewport.project(mid)
            let linearMid = SamplePoint2D(
                x: (screenLeft.x + screenRight.x) / 2.0,
                y: (screenLeft.y + screenRight.y) / 2.0
            )
            error = jumpDistance(screenMid, linearMid)
            threshold = tolerance
        }
        guard error > threshold else { return [left, right] }
        guard producedPoints + 1 < options.maxSampleCount else {
            return [left, right]
        }

        let leftRefined = refineBetween(
            left: left,
            leftT: leftT,
            right: mid,
            rightT: midT,
            depth: depth + 1,
            xExpression: xExpression,
            yExpression: yExpression,
            parameter: parameter,
            baseEnvironment: baseEnvironment,
            refinementMode: refinementMode,
            producedPoints: &producedPoints,
            issues: &issues
        )
        let rightRefined = refineBetween(
            left: mid,
            leftT: midT,
            right: right,
            rightT: rightT,
            depth: depth + 1,
            xExpression: xExpression,
            yExpression: yExpression,
            parameter: parameter,
            baseEnvironment: baseEnvironment,
            refinementMode: refinementMode,
            producedPoints: &producedPoints,
            issues: &issues
        )

        guard let leftRefined, let rightRefined else {
            return nil
        }

        producedPoints += 1
        return Array(leftRefined.dropLast()) + rightRefined
    }

    private func evaluatePoint(
        t: Double,
        xExpression: Expr,
        yExpression: Expr,
        parameter: Symbol,
        baseEnvironment: EvaluationEnvironment
    ) -> SampleOutcome {
        var values = baseEnvironment.values
        values[parameter] = t
        let environment = EvaluationEnvironment(values: values)

        let xResult = evaluator.evaluate(xExpression, environment: environment)
        let yResult = evaluator.evaluate(yExpression, environment: environment)

        switch (xResult, yResult) {
        case (.undefined(let issue), _):
            return SampleOutcome(
                point: nil,
                issues: [SamplingIssue(kind: .evaluationUndefined, message: "t=\(t): x undefined - \(issue.kind.rawValue) - \(issue.message)")]
            )
        case (_, .undefined(let issue)):
            return SampleOutcome(
                point: nil,
                issues: [SamplingIssue(kind: .evaluationUndefined, message: "t=\(t): y undefined - \(issue.kind.rawValue) - \(issue.message)")]
            )
        case (.value(let x), .value(let y)):
            guard x.isFinite, y.isFinite else {
                return SampleOutcome(
                    point: nil,
                    issues: [SamplingIssue(kind: .nonFinitePoint, message: "non-finite sample point at t=\(t), x=\(x), y=\(y)")]
                )
            }
            guard abs(x) <= options.maxAbsCoordinate, abs(y) <= options.maxAbsCoordinate else {
                return SampleOutcome(
                    point: nil,
                    issues: [SamplingIssue(kind: .nonFinitePoint, message: "sample exceeds maxAbsCoordinate at t=\(t), x=\(x), y=\(y)")]
                )
            }
            return SampleOutcome(point: SamplePoint2D(x: x, y: y), issues: [])
        }
    }

    private func jumpDistance(_ a: SamplePoint2D, _ b: SamplePoint2D) -> Double {
        let dx = b.x - a.x
        let dy = b.y - a.y
        return hypot(dx, dy)
    }

    private func shouldRefine(_ mode: RefinementMode) -> Bool {
        switch mode {
        case .none:
            return false
        case .basic, .screen:
            return true
        }
    }
}
