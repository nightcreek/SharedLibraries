import Foundation

public struct PolarCurveSampler2D {
    public var parametricCurveSampler: ParametricCurveSampler2D

    public init(
        parametricCurveSampler: ParametricCurveSampler2D = .init()
    ) {
        self.parametricCurveSampler = parametricCurveSampler
    }

    public func sample(
        radiusExpression: Expr,
        angle: Symbol,
        range: SamplingRange,
        viewport: SamplingViewport2D? = nil,
        environment: EvaluationEnvironment = .init()
    ) -> SampleSet2D {
        let angleExpr = Expr.symbol(angle)
        let xExpression = Expr.multiply([
            radiusExpression,
            .function(.cos, arguments: [angleExpr])
        ])
        let yExpression = Expr.multiply([
            radiusExpression,
            .function(.sin, arguments: [angleExpr])
        ])

        return parametricCurveSampler.sample(
            xExpression: xExpression,
            yExpression: yExpression,
            parameter: angle,
            range: range,
            viewport: viewport,
            environment: environment
        )
    }
}
