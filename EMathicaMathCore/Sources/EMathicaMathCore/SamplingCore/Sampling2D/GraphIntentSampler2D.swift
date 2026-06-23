public struct GraphIntentSampler2D {
    public var explicitFunctionSampler: ExplicitFunctionSampler2D
    public var parametricCurveSampler: ParametricCurveSampler2D
    public var polarCurveSampler: PolarCurveSampler2D
    public var primitiveSampler: PrimitiveSampler2D
    public var implicitCurveSampler: ImplicitCurveSampler2D
    public var piecewiseSampler: PiecewiseSampler2D
    public var conicSampler: ConicSampler2D

    public init(
        explicitFunctionSampler: ExplicitFunctionSampler2D = .init(),
        parametricCurveSampler: ParametricCurveSampler2D = .init(),
        polarCurveSampler: PolarCurveSampler2D = .init(),
        primitiveSampler: PrimitiveSampler2D = .init(),
        implicitCurveSampler: ImplicitCurveSampler2D = .init(),
        piecewiseSampler: PiecewiseSampler2D = .init(),
        conicSampler: ConicSampler2D = .init()
    ) {
        self.explicitFunctionSampler = explicitFunctionSampler
        self.parametricCurveSampler = parametricCurveSampler
        self.polarCurveSampler = polarCurveSampler
        self.primitiveSampler = primitiveSampler
        self.implicitCurveSampler = implicitCurveSampler
        self.piecewiseSampler = piecewiseSampler
        self.conicSampler = conicSampler
    }

    public init(qualityProfile: SamplingQualityProfile) {
        let curveOptions = CurveSamplingOptions2D.defaults(for: qualityProfile)
        let parametricSampler = ParametricCurveSampler2D(options: curveOptions)
        self.explicitFunctionSampler = ExplicitFunctionSampler2D(options: curveOptions)
        self.parametricCurveSampler = parametricSampler
        self.polarCurveSampler = PolarCurveSampler2D(
            parametricCurveSampler: parametricSampler
        )
        self.primitiveSampler = PrimitiveSampler2D(
            parametricCurveSampler: parametricSampler
        )
        self.implicitCurveSampler = ImplicitCurveSampler2D(
            options: .defaults(for: qualityProfile)
        )
        self.piecewiseSampler = PiecewiseSampler2D(options: curveOptions)
        self.conicSampler = ConicSampler2D(
            parametricCurveSampler: parametricSampler,
            explicitFunctionSampler: self.explicitFunctionSampler
        )
    }

    public func sample(
        intent: GraphIntent,
        xRange: SamplingRange,
        yRange: SamplingRange? = nil,
        viewport: SamplingViewport2D? = nil,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        switch intent {
        case .explicitY(let expression, let variable):
            return explicitFunctionSampler.sampleY(
                expression: expression,
                variable: variable,
                range: xRange,
                viewport: viewport,
                environment: environment
            )

        case .explicitX(let expression, let variable):
            return explicitFunctionSampler.sampleX(
                expression: expression,
                variable: variable,
                range: yRange ?? xRange,
                viewport: viewport,
                environment: environment
            )

        case .parametric2D(let xExpression, let yExpression, let parameter, let parameterRange):
            let fallbackRange = combinedVisibleParameterRange(xRange: xRange, yRange: yRange)
            let range = resolveParameterRange(
                parameterRange,
                fallbackVisibleRange: fallbackRange,
                environment: environment
            ) ?? SamplingRange(lower: 0, upper: 2 * Double.pi)
            return parametricCurveSampler.sample(
                xExpression: xExpression,
                yExpression: yExpression,
                parameter: parameter,
                range: range,
                viewport: viewport,
                environment: environment
            )

        case .polar(let radiusExpression, let angle, let parameterRange):
            let fallbackRange = combinedVisibleParameterRange(xRange: xRange, yRange: yRange)
            let range = resolveParameterRange(
                parameterRange,
                fallbackVisibleRange: fallbackRange,
                environment: environment
            ) ?? SamplingRange(lower: 0, upper: 2 * Double.pi)
            return polarCurveSampler.sample(
                radiusExpression: radiusExpression,
                angle: angle,
                range: range,
                viewport: viewport,
                environment: environment
            )

        case .point(let x, let y):
            return primitiveSampler.samplePoint(
                x: x,
                y: y,
                environment: environment
            )

        case .circle(let center, let radius):
            return primitiveSampler.sampleCircle(
                center: center,
                radius: radius,
                viewport: viewport,
                environment: environment
            )

        case .implicit(let relation):
            guard let yRange else {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .invalidRange,
                            message: "Implicit curve sampling requires yRange."
                        )
                    ]
                )
            }
            return implicitCurveSampler.sample(
                relation: relation,
                xRange: xRange,
                yRange: yRange,
                environment: environment
            )

        case .piecewise(let branches):
            let variables = Set(
                branches.compactMap { branch -> Symbol? in
                    guard case .explicitY(_, let variable) = branch.intent else { return nil }
                    return variable
                }
            )
            if variables.count > 1 {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .unsupportedIntent,
                            message: "Piecewise branches use inconsistent explicitY variables."
                        )
                    ]
                )
            }
            let variable = variables.first ?? Symbol(name: "x", role: .variable)
            return piecewiseSampler.sampleY(
                branches: branches,
                variable: variable,
                range: xRange,
                environment: environment
            )

        case .conic(let info):
            return conicSampler.sample(
                info: info,
                xRange: xRange,
                yRange: yRange,
                viewport: viewport,
                environment: environment
            )

        default:
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: .unsupportedIntent,
                        message: "GraphIntentSampler2D does not yet support intent: \(String(describing: intent))"
                    )
                ]
            )
        }
    }

    private func resolveParameterRange(
        _ range: ParameterRange?,
        fallbackVisibleRange: SamplingRange,
        environment: EvaluationEnvironment
    ) -> SamplingRange? {
        guard let range else { return nil }
        let evaluator = ExprEvaluator()

        var lower = fallbackVisibleRange.lower
        var upper = fallbackVisibleRange.upper
        var hasExplicitBound = false

        if let lowerExpr = range.lower {
            let lowerResult = evaluator.evaluate(lowerExpr, environment: environment)
            guard case .value(let explicitLower) = lowerResult, explicitLower.isFinite else {
                return nil
            }
            lower = explicitLower
            hasExplicitBound = true
        }
        if let upperExpr = range.upper {
            let upperResult = evaluator.evaluate(upperExpr, environment: environment)
            guard case .value(let explicitUpper) = upperResult, explicitUpper.isFinite else {
                return nil
            }
            upper = explicitUpper
            hasExplicitBound = true
        }
        guard hasExplicitBound, lower < upper else { return nil }
        return SamplingRange(lower: lower, upper: upper)
    }

    private func combinedVisibleParameterRange(
        xRange: SamplingRange,
        yRange: SamplingRange?
    ) -> SamplingRange {
        guard let yRange else { return xRange }
        return SamplingRange(
            lower: min(xRange.lower, yRange.lower),
            upper: max(xRange.upper, yRange.upper)
        )
    }
}
