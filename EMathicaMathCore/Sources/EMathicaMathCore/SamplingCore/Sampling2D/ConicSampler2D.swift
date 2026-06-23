import Foundation

public struct ConicSampler2D {
    public var parametricCurveSampler: ParametricCurveSampler2D
    public var explicitFunctionSampler: ExplicitFunctionSampler2D

    public init(
        parametricCurveSampler: ParametricCurveSampler2D = .init(),
        explicitFunctionSampler: ExplicitFunctionSampler2D = .init()
    ) {
        self.parametricCurveSampler = parametricCurveSampler
        self.explicitFunctionSampler = explicitFunctionSampler
    }

    public func sample(
        info: ConicInfo,
        xRange: SamplingRange,
        yRange: SamplingRange? = nil,
        viewport: SamplingViewport2D? = nil,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        _ = xRange
        _ = yRange

        guard let canonicalForm = info.canonicalForm else {
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: .unsupportedIntent,
                        message: "Conic sampler requires canonicalForm for semantic conic sampling."
                    )
                ]
            )
        }

        switch canonicalForm {
        case .originEllipse(let a, let b):
            let parameter = Symbol(name: "t", role: .parameter)
            let tExpr = Expr.symbol(parameter)
            let xExpr = Expr.multiply([a, .function(.cos, arguments: [tExpr])])
            let yExpr = Expr.multiply([b, .function(.sin, arguments: [tExpr])])
            return parametricCurveSampler.sample(
                xExpression: xExpr,
                yExpression: yExpr,
                parameter: parameter,
                range: SamplingRange(lower: 0, upper: 2 * Double.pi),
                viewport: viewport,
                environment: environment
            )

        case .originHyperbolaX(let a, let b):
            let parameter = Symbol(name: "t", role: .parameter)
            let tExpr = Expr.symbol(parameter)

            let rightX = Expr.multiply([a, .function(.cosh, arguments: [tExpr])])
            let rightY = Expr.multiply([b, .function(.sinh, arguments: [tExpr])])
            let right = parametricCurveSampler.sample(
                xExpression: rightX,
                yExpression: rightY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            let leftX = Expr.negate(Expr.multiply([a, .function(.cosh, arguments: [tExpr])]))
            let leftY = Expr.multiply([b, .function(.sinh, arguments: [tExpr])])
            let left = parametricCurveSampler.sample(
                xExpression: leftX,
                yExpression: leftY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            return merge(right, left)

        case .originHyperbolaY(let a, let b):
            let parameter = Symbol(name: "t", role: .parameter)
            let tExpr = Expr.symbol(parameter)

            let upperX = Expr.multiply([a, .function(.sinh, arguments: [tExpr])])
            let upperY = Expr.multiply([b, .function(.cosh, arguments: [tExpr])])
            let upper = parametricCurveSampler.sample(
                xExpression: upperX,
                yExpression: upperY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            let lowerX = Expr.multiply([a, .function(.sinh, arguments: [tExpr])])
            let lowerY = Expr.negate(Expr.multiply([b, .function(.cosh, arguments: [tExpr])]))
            let lower = parametricCurveSampler.sample(
                xExpression: lowerX,
                yExpression: lowerY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            return merge(upper, lower)

        case .translatedEllipse(let center, let a, let b):
            if let angle = effectiveRotationAngle(info.rotationAngle) {
                let local = sampleOriginEllipse(a: a, b: b, viewport: viewport, environment: environment)
                return applyRotationTransform(local, centerExpr: center, angle: angle, environment: environment)
            }

            guard case .tuple(let centerItems) = center, centerItems.count == 2 else {
                return invalidCenterTupleIssue()
            }
            let cx = centerItems[0]
            let cy = centerItems[1]
            let parameter = Symbol(name: "t", role: .parameter)
            let tExpr = Expr.symbol(parameter)
            let xExpr = Expr.add([cx, .multiply([a, .function(.cos, arguments: [tExpr])])])
            let yExpr = Expr.add([cy, .multiply([b, .function(.sin, arguments: [tExpr])])])
            return parametricCurveSampler.sample(
                xExpression: xExpr,
                yExpression: yExpr,
                parameter: parameter,
                range: SamplingRange(lower: 0, upper: 2 * Double.pi),
                viewport: viewport,
                environment: environment
            )

        case .translatedHyperbolaX(let center, let a, let b):
            if let angle = effectiveRotationAngle(info.rotationAngle) {
                let local = sampleOriginHyperbolaX(a: a, b: b, viewport: viewport, environment: environment)
                return applyRotationTransform(local, centerExpr: center, angle: angle, environment: environment)
            }

            guard case .tuple(let centerItems) = center, centerItems.count == 2 else {
                return invalidCenterTupleIssue()
            }
            let cx = centerItems[0]
            let cy = centerItems[1]
            let parameter = Symbol(name: "t", role: .parameter)
            let tExpr = Expr.symbol(parameter)

            let rightX = Expr.add([cx, .multiply([a, .function(.cosh, arguments: [tExpr])])])
            let rightY = Expr.add([cy, .multiply([b, .function(.sinh, arguments: [tExpr])])])
            let right = parametricCurveSampler.sample(
                xExpression: rightX,
                yExpression: rightY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            let leftX = Expr.add([cx, .negate(.multiply([a, .function(.cosh, arguments: [tExpr])]))])
            let leftY = Expr.add([cy, .multiply([b, .function(.sinh, arguments: [tExpr])])])
            let left = parametricCurveSampler.sample(
                xExpression: leftX,
                yExpression: leftY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            return merge(right, left)

        case .translatedHyperbolaY(let center, let a, let b):
            if let angle = effectiveRotationAngle(info.rotationAngle) {
                let local = sampleOriginHyperbolaY(a: a, b: b, viewport: viewport, environment: environment)
                return applyRotationTransform(local, centerExpr: center, angle: angle, environment: environment)
            }

            guard case .tuple(let centerItems) = center, centerItems.count == 2 else {
                return invalidCenterTupleIssue()
            }
            let cx = centerItems[0]
            let cy = centerItems[1]
            let parameter = Symbol(name: "t", role: .parameter)
            let tExpr = Expr.symbol(parameter)

            let upperX = Expr.add([cx, .multiply([a, .function(.sinh, arguments: [tExpr])])])
            let upperY = Expr.add([cy, .multiply([b, .function(.cosh, arguments: [tExpr])])])
            let upper = parametricCurveSampler.sample(
                xExpression: upperX,
                yExpression: upperY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            let lowerX = Expr.add([cx, .multiply([a, .function(.sinh, arguments: [tExpr])])])
            let lowerY = Expr.add([cy, .negate(.multiply([b, .function(.cosh, arguments: [tExpr])]))])
            let lower = parametricCurveSampler.sample(
                xExpression: lowerX,
                yExpression: lowerY,
                parameter: parameter,
                range: SamplingRange(lower: -2, upper: 2),
                viewport: viewport,
                environment: environment
            )

            return merge(upper, lower)

        case .translatedParabolaY(let vertex, let coefficient):
            guard case .tuple(let vertexItems) = vertex, vertexItems.count == 2 else {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .unsupportedIntent,
                            message: "Translated parabola vertex must be tuple([h, k])."
                        )
                    ]
                )
            }
            let h = vertexItems[0]
            let k = vertexItems[1]
            let xVar = Symbol(name: "x", role: .variable)
            let xExpr = Expr.symbol(xVar)
            let yExpr = Expr.add([
                Expr.multiply([
                    coefficient,
                    Expr.power(
                        base: Expr.add([xExpr, .negate(h)]),
                        exponent: .integer(2)
                    )
                ]),
                k
            ])
            return explicitFunctionSampler.sampleY(
                expression: yExpr,
                variable: xVar,
                range: xRange,
                viewport: viewport,
                environment: environment
            )

        case .translatedParabolaX(let vertex, let coefficient):
            guard case .tuple(let vertexItems) = vertex, vertexItems.count == 2 else {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .unsupportedIntent,
                            message: "Translated parabola vertex must be tuple([h, k])."
                        )
                    ]
                )
            }
            guard let yRange else {
                return SampleSet2D(
                    segments: [],
                    issues: [
                        SamplingIssue(
                            kind: .invalidRange,
                            message: "Translated parabola X sampling requires yRange."
                        )
                    ]
                )
            }
            let h = vertexItems[0]
            let k = vertexItems[1]
            let yVar = Symbol(name: "y", role: .variable)
            let yExpr = Expr.symbol(yVar)
            let xExpr = Expr.add([
                Expr.multiply([
                    coefficient,
                    Expr.power(
                        base: Expr.add([yExpr, .negate(k)]),
                        exponent: .integer(2)
                    )
                ]),
                h
            ])
            return explicitFunctionSampler.sampleX(
                expression: xExpr,
                variable: yVar,
                range: yRange,
                viewport: viewport,
                environment: environment
            )
        }
    }

    private func merge(_ lhs: SampleSet2D, _ rhs: SampleSet2D) -> SampleSet2D {
        var issues = lhs.issues
        for issue in rhs.issues where !issues.contains(issue) {
            issues.append(issue)
        }
        return SampleSet2D(
            segments: lhs.segments + rhs.segments,
            issues: issues
        )
    }

    private func effectiveRotationAngle(_ rotationAngle: Double?) -> Double? {
        guard let rotationAngle else { return nil }
        return abs(rotationAngle) > 1e-12 ? rotationAngle : nil
    }

    private func invalidCenterTupleIssue() -> SampleSet2D {
        SampleSet2D(
            segments: [],
            issues: [
                SamplingIssue(
                    kind: .unsupportedIntent,
                    message: "Translated conic center must be tuple([cx, cy])."
                )
            ]
        )
    }

    private func applyRotationTransform(
        _ local: SampleSet2D,
        centerExpr: Expr,
        angle: Double,
        environment: EvaluationEnvironment
    ) -> SampleSet2D {
        guard case .tuple(let centerItems) = centerExpr, centerItems.count == 2 else {
            return invalidCenterTupleIssue()
        }
        let evaluator = ExprEvaluator()
        guard case .value(let centerX) = evaluator.evaluate(centerItems[0], environment: environment),
              case .value(let centerY) = evaluator.evaluate(centerItems[1], environment: environment),
              centerX.isFinite, centerY.isFinite else {
            return SampleSet2D(
                segments: [],
                issues: [
                    SamplingIssue(
                        kind: .evaluationUndefined,
                        message: "Translated conic center cannot be evaluated to finite values."
                    )
                ]
            )
        }

        let transform = ConicCoordinateTransform2D(
            centerX: centerX,
            centerY: centerY,
            rotationAngle: angle
        )
        return local.mapPoints { transform.transformLocalToWorld($0) }
    }

    private func sampleOriginEllipse(
        a: Expr,
        b: Expr,
        viewport: SamplingViewport2D?,
        environment: EvaluationEnvironment
    ) -> SampleSet2D {
        let parameter = Symbol(name: "t", role: .parameter)
        let tExpr = Expr.symbol(parameter)
        let xExpr = Expr.multiply([a, .function(.cos, arguments: [tExpr])])
        let yExpr = Expr.multiply([b, .function(.sin, arguments: [tExpr])])
        return parametricCurveSampler.sample(
            xExpression: xExpr,
            yExpression: yExpr,
            parameter: parameter,
            range: SamplingRange(lower: 0, upper: 2 * Double.pi),
            viewport: viewport,
            environment: environment
        )
    }

    private func sampleOriginHyperbolaX(
        a: Expr,
        b: Expr,
        viewport: SamplingViewport2D?,
        environment: EvaluationEnvironment
    ) -> SampleSet2D {
        let parameter = Symbol(name: "t", role: .parameter)
        let tExpr = Expr.symbol(parameter)

        let rightX = Expr.multiply([a, .function(.cosh, arguments: [tExpr])])
        let rightY = Expr.multiply([b, .function(.sinh, arguments: [tExpr])])
        let right = parametricCurveSampler.sample(
            xExpression: rightX,
            yExpression: rightY,
            parameter: parameter,
            range: SamplingRange(lower: -2, upper: 2),
            viewport: viewport,
            environment: environment
        )

        let leftX = Expr.negate(Expr.multiply([a, .function(.cosh, arguments: [tExpr])]))
        let leftY = Expr.multiply([b, .function(.sinh, arguments: [tExpr])])
        let left = parametricCurveSampler.sample(
            xExpression: leftX,
            yExpression: leftY,
            parameter: parameter,
            range: SamplingRange(lower: -2, upper: 2),
            viewport: viewport,
            environment: environment
        )

        return merge(right, left)
    }

    private func sampleOriginHyperbolaY(
        a: Expr,
        b: Expr,
        viewport: SamplingViewport2D?,
        environment: EvaluationEnvironment
    ) -> SampleSet2D {
        let parameter = Symbol(name: "t", role: .parameter)
        let tExpr = Expr.symbol(parameter)

        let upperX = Expr.multiply([a, .function(.sinh, arguments: [tExpr])])
        let upperY = Expr.multiply([b, .function(.cosh, arguments: [tExpr])])
        let upper = parametricCurveSampler.sample(
            xExpression: upperX,
            yExpression: upperY,
            parameter: parameter,
            range: SamplingRange(lower: -2, upper: 2),
            viewport: viewport,
            environment: environment
        )

        let lowerX = Expr.multiply([a, .function(.sinh, arguments: [tExpr])])
        let lowerY = Expr.negate(Expr.multiply([b, .function(.cosh, arguments: [tExpr])]))
        let lower = parametricCurveSampler.sample(
            xExpression: lowerX,
            yExpression: lowerY,
            parameter: parameter,
            range: SamplingRange(lower: -2, upper: 2),
            viewport: viewport,
            environment: environment
        )

        return merge(upper, lower)
    }
}
