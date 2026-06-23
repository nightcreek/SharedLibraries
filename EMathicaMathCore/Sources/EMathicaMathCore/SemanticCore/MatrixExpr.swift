public struct MatrixExpr: Codable, Equatable, Sendable {
    public var rows: [[Expr]]

    public init(rows: [[Expr]]) {
        self.rows = rows
    }
}
