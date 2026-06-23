public indirect enum GraphIntent: Equatable, Sendable {
    case explicitY(expression: Expr, variable: Symbol)
    case explicitX(expression: Expr, variable: Symbol)

    case implicit(relation: Expr)

    case parametric2D(
        x: Expr,
        y: Expr,
        parameter: Symbol,
        range: ParameterRange?
    )

    case polar(
        radius: Expr,
        angle: Symbol,
        range: ParameterRange?
    )

    case point(x: Expr, y: Expr)

    case circle(center: Expr, radius: Expr)

    case conic(ConicInfo)

    case piecewise([GraphIntentBranch])

    case unknown(Expr)
}

public struct GraphIntentBranch: Equatable, Sendable {
    public var condition: Expr
    public var intent: GraphIntent

    public init(condition: Expr, intent: GraphIntent) {
        self.condition = condition
        self.intent = intent
    }
}
