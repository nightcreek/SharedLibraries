import Foundation

public struct PrimitiveSampler2D {
    public var evaluator: ExprEvaluator
    public var parametricCurveSampler: ParametricCurveSampler2D

    public init(
        evaluator: ExprEvaluator = .init(),
        parametricCurveSampler: ParametricCurveSampler2D = .init()
    ) {
        self.evaluator = evaluator
        self.parametricCurveSampler = parametricCurveSampler
    }

    public func samplePoint(
        x: Expr,
        y: Expr,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        let xResult = evaluator.evaluate(x, environment: environment)
        let yResult = evaluator.evaluate(y, environment: environment)

        switch (xResult, yResult) {
        case (.undefined(let issue), _):
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: samplingKind(for: issue),
                        message: "point x is undefined: \(issue.kind.rawValue) - \(issue.message)"
                    )
                ]
            )
        case (_, .undefined(let issue)):
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: samplingKind(for: issue),
                        message: "point y is undefined: \(issue.kind.rawValue) - \(issue.message)"
                    )
                ]
            )
        case (.value(let xv), .value(let yv)):
            guard xv.isFinite, yv.isFinite else {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .nonFinitePoint,
                            message: "point is non-finite: (\(xv), \(yv))"
                        )
                    ]
                )
            }

            // Sampling-7 representation: a point is modeled as a one-point segment.
            // Future work can migrate this into a dedicated point primitive type.
            return SampleSet2D(
                segments: [
                    SampleSegment2D(points: [
                        SamplePoint2D(x: xv, y: yv)
                    ])
                ],
                issues: []
            )
        }
    }

    public func sampleCircle(
        center: Expr,
        radius: Expr,
        viewport: SamplingViewport2D? = nil,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        guard case .tuple(let items) = center, items.count == 2 else {
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: .unsupportedIntent,
                        message: "circle center must be tuple([cx, cy])"
                    )
                ]
            )
        }

        let cxResult = evaluator.evaluate(items[0], environment: environment)
        let cyResult = evaluator.evaluate(items[1], environment: environment)
        let radiusResult = evaluator.evaluate(radius, environment: environment)

        switch (cxResult, cyResult, radiusResult) {
        case (.undefined(let issue), _, _):
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: samplingKind(for: issue),
                        message: "circle center x is undefined: \(issue.kind.rawValue) - \(issue.message)"
                    )
                ]
            )
        case (_, .undefined(let issue), _):
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: samplingKind(for: issue),
                        message: "circle center y is undefined: \(issue.kind.rawValue) - \(issue.message)"
                    )
                ]
            )
        case (_, _, .undefined(let issue)):
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: samplingKind(for: issue),
                        message: "circle radius is undefined: \(issue.kind.rawValue) - \(issue.message)"
                    )
                ]
            )
        case (.value(let cx), .value(let cy), .value(let r)):
            guard cx.isFinite, cy.isFinite, r.isFinite else {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .nonFinitePoint,
                            message: "circle contains non-finite component: center=(\(cx),\(cy)) radius=\(r)"
                        )
                    ]
                )
            }
            guard r > 0 else {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .unsupportedIntent,
                            message: "invalid circle radius: \(r)"
                        )
                    ]
                )
            }

            let t = Symbol(name: "t", role: .parameter)
            let tExpr = Expr.symbol(t)
            let xExpr = Expr.add([
                .real(cx),
                .multiply([
                    .real(r),
                    .function(.cos, arguments: [tExpr])
                ])
            ])
            let yExpr = Expr.add([
                .real(cy),
                .multiply([
                    .real(r),
                    .function(.sin, arguments: [tExpr])
                ])
            ])

            return parametricCurveSampler.sample(
                xExpression: xExpr,
                yExpression: yExpr,
                parameter: t,
                range: SamplingRange(lower: 0, upper: 2 * Double.pi),
                viewport: viewport,
                environment: environment
            )
        }
    }

    private func samplingKind(for issue: EvaluationIssue) -> SamplingIssueKind {
        issue.kind == .nonFiniteResult ? .nonFinitePoint : .evaluationUndefined
    }
}
