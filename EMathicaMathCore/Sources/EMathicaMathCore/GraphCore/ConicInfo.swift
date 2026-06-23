public enum ConicCanonicalForm: Codable, Equatable, Sendable {
    case originEllipse(a: Expr, b: Expr)
    case originHyperbolaX(a: Expr, b: Expr)
    case originHyperbolaY(a: Expr, b: Expr)
    case translatedEllipse(center: Expr, a: Expr, b: Expr)
    case translatedHyperbolaX(center: Expr, a: Expr, b: Expr)
    case translatedHyperbolaY(center: Expr, a: Expr, b: Expr)
    case translatedParabolaY(vertex: Expr, coefficient: Expr)
    case translatedParabolaX(vertex: Expr, coefficient: Expr)
}

public enum ConicOrientation: String, Codable, Equatable, Sendable {
    case axisAligned
    case rotated
    case unknown
}

public struct ConicInfo: Codable, Equatable, Sendable {
    public var kind: ConicKind
    public var source: Expr
    public var canonicalForm: ConicCanonicalForm?
    public var orientation: ConicOrientation?
    public var rotationAngle: Double?

    public init(
        kind: ConicKind,
        source: Expr,
        canonicalForm: ConicCanonicalForm? = nil,
        orientation: ConicOrientation? = nil,
        rotationAngle: Double? = nil
    ) {
        self.kind = kind
        self.source = source
        self.canonicalForm = canonicalForm
        self.orientation = orientation
        self.rotationAngle = rotationAngle
    }
}

public enum ConicKind: String, Codable, Sendable {
    case circle
    case ellipse
    case parabola
    case hyperbola
    case unknown
}
