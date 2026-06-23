import Foundation

public struct ExplicitFunctionSampler2D {
    public var evaluator: ExprEvaluator
    public var options: CurveSamplingOptions2D

    public init(
        evaluator: ExprEvaluator = .init(),
        options: CurveSamplingOptions2D = .defaults(for: .balanced)
    ) {
        self.evaluator = evaluator
        self.options = options
    }

    public func sampleY(
        expression: Expr,
        variable: Symbol,
        range: SamplingRange,
        viewport: SamplingViewport2D? = nil,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        sample(
            expression: expression,
            variable: variable,
            range: range,
            viewport: viewport,
            baseEnvironment: environment,
            pointBuilder: { sampled, evaluated in
                SamplePoint2D(x: sampled, y: evaluated)
            },
            jumpDelta: { previous, current in
                abs(current.y - previous.y)
            },
            sampledMidValue: { left, right in
                (left.x + right.x) / 2.0
            },
            midpointDelta: { left, right in
                abs(right.x - left.x)
            },
            midpointError: { left, right, mid in
                let linear = (left.y + right.y) / 2.0
                return abs(mid.y - linear)
            }
        )
    }

    public func sampleX(
        expression: Expr,
        variable: Symbol,
        range: SamplingRange,
        viewport: SamplingViewport2D? = nil,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        sample(
            expression: expression,
            variable: variable,
            range: range,
            viewport: viewport,
            baseEnvironment: environment,
            pointBuilder: { sampled, evaluated in
                SamplePoint2D(x: evaluated, y: sampled)
            },
            jumpDelta: { previous, current in
                abs(current.x - previous.x)
            },
            sampledMidValue: { left, right in
                (left.y + right.y) / 2.0
            },
            midpointDelta: { left, right in
                abs(right.y - left.y)
            },
            midpointError: { left, right, mid in
                let linear = (left.x + right.x) / 2.0
                return abs(mid.x - linear)
            }
        )
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

    private func sample(
        expression: Expr,
        variable: Symbol,
        range: SamplingRange,
        viewport: SamplingViewport2D?,
        baseEnvironment: EvaluationEnvironment,
        pointBuilder: (Double, Double) -> SamplePoint2D,
        jumpDelta: (SamplePoint2D, SamplePoint2D) -> Double,
        sampledMidValue: (SamplePoint2D, SamplePoint2D) -> Double,
        midpointDelta: (SamplePoint2D, SamplePoint2D) -> Double,
        midpointError: (SamplePoint2D, SamplePoint2D, SamplePoint2D) -> Double
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
            let sampledValue = range.lower + Double(i) * step
            let outcome = evaluatePoint(
                sampledValue: sampledValue,
                expression: expression,
                variable: variable,
                baseEnvironment: baseEnvironment,
                pointBuilder: pointBuilder
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
                if jumpDelta(previous, point) > options.discontinuityThreshold {
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
                        right: point,
                        depth: 0,
                        expression: expression,
                        variable: variable,
                        baseEnvironment: baseEnvironment,
                        pointBuilder: pointBuilder,
                        jumpDelta: jumpDelta,
                        sampledMidValue: sampledMidValue,
                        midpointDelta: midpointDelta,
                        midpointError: midpointError,
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

        return SampleSet2D(
            segments: cappedSegments(segments, limit: options.maxSampleCount),
            issues: issues
        )
    }

    private func cappedSegments(_ segments: [SampleSegment2D], limit: Int) -> [SampleSegment2D] {
        guard limit > 0 else { return [] }
        var remaining = limit
        var result: [SampleSegment2D] = []

        for segment in segments {
            guard remaining > 0 else { break }
            guard !segment.points.isEmpty else { continue }
            if segment.points.count <= remaining {
                result.append(segment)
                remaining -= segment.points.count
            } else {
                let truncated = Array(segment.points.prefix(remaining))
                if !truncated.isEmpty {
                    result.append(.init(points: truncated))
                }
                remaining = 0
            }
        }

        return result
    }

    private func shouldRefine(_ mode: RefinementMode) -> Bool {
        switch mode {
        case .none:
            return false
        case .basic, .screen:
            return true
        }
    }

    private func refineBetween(
        left: SamplePoint2D,
        right: SamplePoint2D,
        depth: Int,
        expression: Expr,
        variable: Symbol,
        baseEnvironment: EvaluationEnvironment,
        pointBuilder: (Double, Double) -> SamplePoint2D,
        jumpDelta: (SamplePoint2D, SamplePoint2D) -> Double,
        sampledMidValue: (SamplePoint2D, SamplePoint2D) -> Double,
        midpointDelta: (SamplePoint2D, SamplePoint2D) -> Double,
        midpointError: (SamplePoint2D, SamplePoint2D, SamplePoint2D) -> Double,
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

        let sampledMid = sampledMidValue(left, right)
        let midOutcome = evaluatePoint(
            sampledValue: sampledMid,
            expression: expression,
            variable: variable,
            baseEnvironment: baseEnvironment,
            pointBuilder: pointBuilder
        )
        issues.append(contentsOf: midOutcome.issues)

        guard let mid = midOutcome.point else {
            return nil
        }

        if jumpDelta(left, mid) > options.discontinuityThreshold || jumpDelta(mid, right) > options.discontinuityThreshold {
            issues.append(.init(
                kind: .possibleDiscontinuity,
                message: "refinement jump detected near midpoint (\(mid.x),\(mid.y))"
            ))
            return nil
        }

        let width = midpointDelta(left, right)
        if width <= .ulpOfOne {
            return [left, right]
        }

        let error: Double
        let threshold: Double
        switch refinementMode {
        case .none:
            return [left, right]
        case .basic:
            error = midpointError(left, right, mid)
            threshold = options.refinementErrorThreshold
        case .screen(let viewport, let tolerance):
            let screenLeft = viewport.project(left)
            let screenRight = viewport.project(right)
            let screenMid = viewport.project(mid)
            let linearMid = SamplePoint2D(
                x: (screenLeft.x + screenRight.x) / 2.0,
                y: (screenLeft.y + screenRight.y) / 2.0
            )
            error = hypot(screenMid.x - linearMid.x, screenMid.y - linearMid.y)
            threshold = tolerance
        }
        guard error > threshold else { return [left, right] }
        guard producedPoints + 1 < options.maxSampleCount else {
            return [left, right]
        }

        let leftRefined = refineBetween(
            left: left,
            right: mid,
            depth: depth + 1,
            expression: expression,
            variable: variable,
            baseEnvironment: baseEnvironment,
            pointBuilder: pointBuilder,
            jumpDelta: jumpDelta,
            sampledMidValue: sampledMidValue,
            midpointDelta: midpointDelta,
            midpointError: midpointError,
            refinementMode: refinementMode,
            producedPoints: &producedPoints,
            issues: &issues
        )
        let rightRefined = refineBetween(
            left: mid,
            right: right,
            depth: depth + 1,
            expression: expression,
            variable: variable,
            baseEnvironment: baseEnvironment,
            pointBuilder: pointBuilder,
            jumpDelta: jumpDelta,
            sampledMidValue: sampledMidValue,
            midpointDelta: midpointDelta,
            midpointError: midpointError,
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
        sampledValue: Double,
        expression: Expr,
        variable: Symbol,
        baseEnvironment: EvaluationEnvironment,
        pointBuilder: (Double, Double) -> SamplePoint2D
    ) -> SampleOutcome {
        var values = baseEnvironment.values
        values[variable] = sampledValue
        let env = EvaluationEnvironment(values: values)
        let eval = evaluator.evaluate(expression, environment: env)

        switch eval {
        case .undefined(let issue):
            return SampleOutcome(
                point: nil,
                issues: [
                    SamplingIssue(
                        kind: .evaluationUndefined,
                        message: "sample=\(sampledValue): \(issue.kind.rawValue) - \(issue.message)"
                    )
                ]
            )

        case .value(let evaluated):
            let point = pointBuilder(sampledValue, evaluated)
            guard point.x.isFinite, point.y.isFinite else {
                return SampleOutcome(
                    point: nil,
                    issues: [SamplingIssue(kind: .nonFinitePoint, message: "non-finite sample point at x=\(point.x), y=\(point.y)")]
                )
            }
            guard abs(point.x) <= options.maxAbsCoordinate, abs(point.y) <= options.maxAbsCoordinate else {
                return SampleOutcome(
                    point: nil,
                    issues: [SamplingIssue(kind: .nonFinitePoint, message: "sample exceeds maxAbsCoordinate at x=\(point.x), y=\(point.y)")]
                )
            }
            return SampleOutcome(point: point, issues: [])
        }
    }
}
