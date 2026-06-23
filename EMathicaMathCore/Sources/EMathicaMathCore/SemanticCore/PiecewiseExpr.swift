public struct PiecewiseBranch: Codable, Equatable, Sendable {
    public var value: Expr
    public var condition: Expr

    public init(value: Expr, condition: Expr) {
        self.value = value
        self.condition = condition
    }
}
