public struct SampleSegment2D: Equatable, Sendable {
    public var points: [SamplePoint2D]

    public init(points: [SamplePoint2D]) {
        self.points = points
    }
}
