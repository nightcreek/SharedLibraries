public struct ParameterRange: Codable, Equatable, Sendable {
    public var lower: Expr?
    public var upper: Expr?

    public init(lower: Expr? = nil, upper: Expr? = nil) {
        self.lower = lower
        self.upper = upper
    }
}
